import os
from datetime import datetime
from functools import wraps
from math import ceil
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt
from werkzeug.utils import secure_filename
from ..models import Student, Admin, Subject, Mark, Attendance, Resource, UpcomingExam, AppConfig
from ..extensions import db
from ..utils import error_response, paginate_query, allowed_file, parse_date, validate_mark_value

api_admin_bp = Blueprint('api_admin', __name__)


def admin_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        if get_jwt().get('role') != 'admin':
            return error_response('Admin access required', 403, 'FORBIDDEN')
        return fn(*args, **kwargs)
    wrapper.__name__ = fn.__name__
    return wrapper


# ── Overview ────────────────────────────────────────────────────────────────

@api_admin_bp.route('/overview', methods=['GET'])
@admin_required
def overview():
    batch = request.args.get('batch')
    center = request.args.get('center')

    q = Student.query.filter_by(is_active=True)
    if batch:
        q = q.filter_by(batch=batch)
    if center:
        q = q.filter_by(center=center)
    students = q.all()
    student_ids = [s.id for s in students]

    if student_ids:
        all_marks = Mark.query.filter(Mark.student_id.in_(student_ids)).all()
    else:
        all_marks = []

    grade_dist = {'A': 0, 'B': 0, 'C': 0, 'S': 0, 'F': 0}
    for m in all_marks:
        grade_dist[m.grade] = grade_dist.get(m.grade, 0) + 1

    overall_avg = round(sum(m.percentage for m in all_marks) / len(all_marks), 2) if all_marks else 0.0

    top_scorer = None
    if students:
        top_s = max(students, key=lambda s: s.get_average_percentage())
        top_scorer = {**top_s.to_dict(),
                      'average_percentage': top_s.get_average_percentage(),
                      'best_grade': top_s.get_best_grade()}

    batches = [b[0] for b in db.session.query(Student.batch).distinct().filter(Student.batch != None).all()]
    centers = [c[0] for c in db.session.query(Student.center).distinct().filter(Student.center != None).all()]

    return jsonify({
        'success': True,
        'data': {
            'total_students': len(students),
            'total_subjects': Subject.query.count(),
            'total_marks_entered': len(all_marks),
            'overall_average': overall_avg,
            'grade_distribution': grade_dist,
            'top_scorer': top_scorer,
            'available_batches': batches,
            'available_centers': centers,
        },
    }), 200


# ── Students ─────────────────────────────────────────────────────────────────

@api_admin_bp.route('/students', methods=['GET'])
@admin_required
def list_students():
    page = max(1, int(request.args.get('page', 1)))
    per_page = min(100, int(request.args.get('per_page', 20)))
    search = request.args.get('search', '').strip()
    batch = request.args.get('batch')
    center = request.args.get('center')

    q = Student.query
    if search:
        q = q.filter(db.or_(
            Student.name.ilike(f'%{search}%'),
            Student.index_number.ilike(f'%{search}%'),
            Student.email.ilike(f'%{search}%'),
        ))
    if batch:
        q = q.filter_by(batch=batch)
    if center:
        q = q.filter_by(center=center)
    q = q.order_by(Student.name)

    result = paginate_query(q, page, per_page, serialize_fn=lambda s: s.to_dict_with_stats())
    return jsonify({'success': True, **result}), 200


@api_admin_bp.route('/students/<int:student_id>', methods=['GET'])
@admin_required
def get_student(student_id):
    student = Student.query.get_or_404(student_id)
    return jsonify({'success': True, 'data': student.to_dict_with_stats()}), 200


@api_admin_bp.route('/students', methods=['POST'])
@admin_required
def create_student():
    data = request.get_json(silent=True)
    if not data:
        return error_response('JSON body required', 400, 'BAD_REQUEST')

    index_number = (data.get('index_number') or '').strip()
    name = (data.get('name') or '').strip()
    password = data.get('password') or ''

    if not index_number or not name or not password:
        return error_response('index_number, name, and password are required', 422, 'VALIDATION_ERROR')

    if Student.query.filter_by(index_number=index_number).first():
        return error_response('Index number already exists', 409, 'CONFLICT')

    student = Student(
        index_number=index_number,
        name=name,
        email=data.get('email') or None,
        phone=data.get('phone') or None,
        batch=data.get('batch') or None,
        center=data.get('center') or None,
    )
    student.set_password(password)
    db.session.add(student)
    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return error_response(str(e), 500, 'DB_ERROR')
    return jsonify({'success': True, 'data': student.to_dict()}), 201


@api_admin_bp.route('/students/<int:student_id>', methods=['PUT'])
@admin_required
def update_student(student_id):
    student = Student.query.get_or_404(student_id)
    data = request.get_json(silent=True) or {}

    if 'name' in data:
        student.name = data['name'].strip()
    if 'email' in data:
        student.email = data['email'] or None
    if 'phone' in data:
        student.phone = data['phone'] or None
    if 'batch' in data:
        student.batch = data['batch'] or None
    if 'center' in data:
        student.center = data['center'] or None
    if 'is_active' in data:
        student.is_active = bool(data['is_active'])
    if data.get('password'):
        student.set_password(data['password'])

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return error_response(str(e), 500, 'DB_ERROR')
    return jsonify({'success': True, 'data': student.to_dict()}), 200


@api_admin_bp.route('/students/<int:student_id>', methods=['DELETE'])
@admin_required
def delete_student(student_id):
    student = Student.query.get_or_404(student_id)
    db.session.delete(student)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Student deleted'}), 200


# ── Subjects ─────────────────────────────────────────────────────────────────

@api_admin_bp.route('/subjects', methods=['GET'])
@admin_required
def list_subjects():
    subjects = Subject.query.order_by(Subject.name).all()
    return jsonify({'success': True, 'data': [s.to_dict() for s in subjects]}), 200


@api_admin_bp.route('/subjects', methods=['POST'])
@admin_required
def create_subject():
    data = request.get_json(silent=True) or {}
    name = (data.get('name') or '').strip()
    if not name:
        return error_response('name is required', 422, 'VALIDATION_ERROR')
    subj = Subject(name=name, code=data.get('code') or None, description=data.get('description') or None)
    db.session.add(subj)
    db.session.commit()
    return jsonify({'success': True, 'data': subj.to_dict()}), 201


@api_admin_bp.route('/subjects/<int:subject_id>', methods=['PUT'])
@admin_required
def update_subject(subject_id):
    subj = Subject.query.get_or_404(subject_id)
    data = request.get_json(silent=True) or {}
    if 'name' in data:
        subj.name = data['name'].strip()
    if 'code' in data:
        subj.code = data['code'] or None
    if 'description' in data:
        subj.description = data['description'] or None
    db.session.commit()
    return jsonify({'success': True, 'data': subj.to_dict()}), 200


@api_admin_bp.route('/subjects/<int:subject_id>', methods=['DELETE'])
@admin_required
def delete_subject(subject_id):
    subj = Subject.query.get_or_404(subject_id)
    db.session.delete(subj)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Subject deleted'}), 200


# ── Marks ─────────────────────────────────────────────────────────────────────

@api_admin_bp.route('/marks', methods=['GET'])
@admin_required
def list_marks():
    page = max(1, int(request.args.get('page', 1)))
    per_page = min(200, int(request.args.get('per_page', 30)))
    student_id = request.args.get('student_id')
    subject_id = request.args.get('subject_id')
    exam_type = request.args.get('exam_type')
    batch = request.args.get('batch')

    q = Mark.query
    if student_id:
        q = q.filter(Mark.student_id == int(student_id))
    if subject_id:
        q = q.filter(Mark.subject_id == int(subject_id))
    if exam_type:
        q = q.filter(Mark.exam_type == exam_type)
    if batch:
        student_ids = [s.id for s in Student.query.filter_by(batch=batch).all()]
        q = q.filter(Mark.student_id.in_(student_ids))
    q = q.order_by(Mark.date.desc())

    result = paginate_query(q, page, per_page, serialize_fn=lambda m: m.to_dict())
    return jsonify({'success': True, **result}), 200


@api_admin_bp.route('/marks', methods=['POST'])
@admin_required
def create_mark():
    data = request.get_json(silent=True) or {}
    student_id = data.get('student_id')
    subject_id = data.get('subject_id')
    mark_val = data.get('mark')
    total = data.get('total_marks', 100.0)

    if student_id is None or subject_id is None or mark_val is None:
        return error_response('student_id, subject_id, mark are required', 422, 'VALIDATION_ERROR')

    if not Student.query.get(student_id):
        return error_response('Student not found', 404, 'NOT_FOUND')
    if not Subject.query.get(subject_id):
        return error_response('Subject not found', 404, 'NOT_FOUND')

    m_val, err = validate_mark_value(mark_val, total)
    if err:
        return error_response(err, 422, 'INVALID_MARK')

    m = Mark(
        student_id=student_id,
        subject_id=subject_id,
        exam_type=data.get('exam_type') or None,
        pack=data.get('pack') or None,
        mark=m_val,
        total_marks=float(total),
        date=parse_date(data.get('date')),
    )
    db.session.add(m)
    db.session.commit()
    return jsonify({'success': True, 'data': m.to_dict()}), 201


@api_admin_bp.route('/marks/<int:mark_id>', methods=['PUT'])
@admin_required
def update_mark(mark_id):
    m = Mark.query.get_or_404(mark_id)
    data = request.get_json(silent=True) or {}

    if 'mark' in data or 'total_marks' in data:
        new_mark = data.get('mark', m.mark)
        new_total = data.get('total_marks', m.total_marks)
        val, err = validate_mark_value(new_mark, new_total)
        if err:
            return error_response(err, 422, 'INVALID_MARK')
        m.mark = val
        m.total_marks = float(new_total)
    if 'exam_type' in data:
        m.exam_type = data['exam_type'] or None
    if 'pack' in data:
        m.pack = data['pack'] or None
    if 'date' in data:
        m.date = parse_date(data['date'])

    db.session.commit()
    return jsonify({'success': True, 'data': m.to_dict()}), 200


@api_admin_bp.route('/marks/<int:mark_id>', methods=['DELETE'])
@admin_required
def delete_mark(mark_id):
    m = Mark.query.get_or_404(mark_id)
    db.session.delete(m)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Mark deleted'}), 200


@api_admin_bp.route('/marks/bulk', methods=['POST'])
@admin_required
def bulk_create_marks():
    """
    Accepts { "entries": [...] } and processes each row independently.
    Per-row success/failure is returned so the caller knows which rows failed.

    NOTE: For a single class of 40 students this runs synchronously in < 200 ms
    on SQLite. If you grow to thousands of rows per request, move to a background
    job and add a status-polling endpoint.
    """
    data = request.get_json(silent=True)
    if not data or 'entries' not in data:
        return error_response('Missing entries array', 422, 'VALIDATION_ERROR')

    entries = data['entries']
    if not isinstance(entries, list) or len(entries) == 0:
        return error_response('entries must be a non-empty array', 422, 'VALIDATION_ERROR')

    # Pre-fetch all referenced students and subjects to avoid N+1 queries
    raw_student_ids = {e.get('student_id') for e in entries if e.get('student_id') is not None}
    raw_subject_ids = {e.get('subject_id') for e in entries if e.get('subject_id') is not None}

    students_map = {s.id: s for s in Student.query.filter(Student.id.in_(raw_student_ids)).all()}
    subjects_map = {s.id: s for s in Subject.query.filter(Subject.id.in_(raw_subject_ids)).all()}

    results = []
    success_count = 0
    error_count = 0

    for i, entry in enumerate(entries):
        student_id = entry.get('student_id')
        subject_id = entry.get('subject_id')
        mark_raw = entry.get('mark')
        total_raw = entry.get('total_marks', 100.0)
        exam_type = entry.get('exam_type') or None
        pack = entry.get('pack') or None
        date_val = parse_date(entry.get('date'))

        # Required field check
        if student_id is None or subject_id is None or mark_raw is None:
            results.append({'index': i, 'success': False,
                            'error': 'Missing student_id, subject_id, or mark', 'code': 'MISSING_FIELDS'})
            error_count += 1
            continue

        # Existence checks
        if int(student_id) not in students_map:
            results.append({'index': i, 'success': False,
                            'error': f'Student {student_id} not found', 'code': 'NOT_FOUND'})
            error_count += 1
            continue
        if int(subject_id) not in subjects_map:
            results.append({'index': i, 'success': False,
                            'error': f'Subject {subject_id} not found', 'code': 'NOT_FOUND'})
            error_count += 1
            continue

        # Mark value validation
        m_val, err = validate_mark_value(mark_raw, total_raw)
        if err:
            results.append({'index': i, 'success': False, 'error': err, 'code': 'INVALID_MARK'})
            error_count += 1
            continue

        # Upsert: update existing row or create new one
        existing = Mark.query.filter_by(
            student_id=int(student_id),
            subject_id=int(subject_id),
            exam_type=exam_type,
            pack=pack,
        ).first()

        if existing:
            existing.mark = m_val
            existing.total_marks = float(total_raw)
            if date_val:
                existing.date = date_val
            results.append({'index': i, 'success': True, 'action': 'updated', 'id': existing.id})
        else:
            new_mark = Mark(
                student_id=int(student_id),
                subject_id=int(subject_id),
                exam_type=exam_type,
                pack=pack,
                mark=m_val,
                total_marks=float(total_raw),
                date=date_val,
            )
            db.session.add(new_mark)
            db.session.flush()
            results.append({'index': i, 'success': True, 'action': 'created', 'id': new_mark.id})

        success_count += 1

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return error_response(f'Database error: {str(e)}', 500, 'DB_ERROR')

    return jsonify({
        'success': True,
        'message': f'Processed {len(entries)} entries: {success_count} succeeded, {error_count} failed',
        'summary': {'total': len(entries), 'success': success_count, 'failed': error_count},
        'results': results,
    }), 200


# ── Attendance ───────────────────────────────────────────────────────────────

@api_admin_bp.route('/attendance', methods=['GET'])
@admin_required
def list_attendance():
    page = max(1, int(request.args.get('page', 1)))
    per_page = min(200, int(request.args.get('per_page', 30)))
    student_id = request.args.get('student_id')
    subject_id = request.args.get('subject_id')
    exam_type = request.args.get('exam_type')

    q = Attendance.query
    if student_id:
        q = q.filter(Attendance.student_id == int(student_id))
    if subject_id:
        q = q.filter(Attendance.subject_id == int(subject_id))
    if exam_type:
        q = q.filter(Attendance.exam_type == exam_type)
    q = q.order_by(Attendance.date.desc())

    result = paginate_query(q, page, per_page, serialize_fn=lambda a: a.to_dict())
    return jsonify({'success': True, **result}), 200


@api_admin_bp.route('/attendance', methods=['POST'])
@admin_required
def create_attendance():
    data = request.get_json(silent=True) or {}
    student_id = data.get('student_id')
    subject_id = data.get('subject_id')

    if not student_id or not subject_id:
        return error_response('student_id and subject_id are required', 422, 'VALIDATION_ERROR')

    if not Student.query.get(student_id):
        return error_response('Student not found', 404, 'NOT_FOUND')
    if not Subject.query.get(subject_id):
        return error_response('Subject not found', 404, 'NOT_FOUND')

    a = Attendance(
        student_id=student_id,
        subject_id=subject_id,
        session_name=data.get('session_name') or None,
        exam_type=data.get('exam_type') or None,
        date=parse_date(data.get('date')),
        is_present=bool(data.get('is_present', True)),
    )
    db.session.add(a)
    db.session.commit()
    return jsonify({'success': True, 'data': a.to_dict()}), 201


@api_admin_bp.route('/attendance/bulk', methods=['POST'])
@admin_required
def bulk_attendance():
    """
    { "entries": [{"student_id": ..., "subject_id": ..., "is_present": bool,
                   "session_name": ..., "exam_type": ..., "date": "YYYY-MM-DD"}, ...] }
    Returns per-row results.
    """
    data = request.get_json(silent=True)
    if not data or 'entries' not in data:
        return error_response('Missing entries array', 422, 'VALIDATION_ERROR')

    entries = data['entries']
    if not isinstance(entries, list) or len(entries) == 0:
        return error_response('entries must be a non-empty array', 422, 'VALIDATION_ERROR')

    raw_student_ids = {e.get('student_id') for e in entries if e.get('student_id') is not None}
    raw_subject_ids = {e.get('subject_id') for e in entries if e.get('subject_id') is not None}

    students_map = {s.id: s for s in Student.query.filter(Student.id.in_(raw_student_ids)).all()}
    subjects_map = {s.id: s for s in Subject.query.filter(Subject.id.in_(raw_subject_ids)).all()}

    results = []
    success_count = 0
    error_count = 0

    for i, entry in enumerate(entries):
        student_id = entry.get('student_id')
        subject_id = entry.get('subject_id')

        if student_id is None or subject_id is None:
            results.append({'index': i, 'success': False,
                            'error': 'Missing student_id or subject_id', 'code': 'MISSING_FIELDS'})
            error_count += 1
            continue

        if int(student_id) not in students_map:
            results.append({'index': i, 'success': False,
                            'error': f'Student {student_id} not found', 'code': 'NOT_FOUND'})
            error_count += 1
            continue
        if int(subject_id) not in subjects_map:
            results.append({'index': i, 'success': False,
                            'error': f'Subject {subject_id} not found', 'code': 'NOT_FOUND'})
            error_count += 1
            continue

        session_name = entry.get('session_name') or None
        exam_type = entry.get('exam_type') or None
        date_val = parse_date(entry.get('date'))
        is_present = bool(entry.get('is_present', True))

        # Upsert by (student, subject, session_name, date)
        existing = Attendance.query.filter_by(
            student_id=int(student_id),
            subject_id=int(subject_id),
            session_name=session_name,
            date=date_val,
        ).first()

        if existing:
            existing.is_present = is_present
            existing.exam_type = exam_type
            results.append({'index': i, 'success': True, 'action': 'updated', 'id': existing.id})
        else:
            new_a = Attendance(
                student_id=int(student_id),
                subject_id=int(subject_id),
                session_name=session_name,
                exam_type=exam_type,
                date=date_val,
                is_present=is_present,
            )
            db.session.add(new_a)
            db.session.flush()
            results.append({'index': i, 'success': True, 'action': 'created', 'id': new_a.id})

        success_count += 1

    try:
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return error_response(f'Database error: {str(e)}', 500, 'DB_ERROR')

    return jsonify({
        'success': True,
        'message': f'Processed {len(entries)} entries: {success_count} succeeded, {error_count} failed',
        'summary': {'total': len(entries), 'success': success_count, 'failed': error_count},
        'results': results,
    }), 200


@api_admin_bp.route('/attendance/<int:att_id>', methods=['PUT'])
@admin_required
def update_attendance(att_id):
    a = Attendance.query.get_or_404(att_id)
    data = request.get_json(silent=True) or {}
    if 'is_present' in data:
        a.is_present = bool(data['is_present'])
    if 'session_name' in data:
        a.session_name = data['session_name'] or None
    if 'exam_type' in data:
        a.exam_type = data['exam_type'] or None
    if 'date' in data:
        a.date = parse_date(data['date'])
    db.session.commit()
    return jsonify({'success': True, 'data': a.to_dict()}), 200


# ── Resources ────────────────────────────────────────────────────────────────

@api_admin_bp.route('/resources', methods=['GET'])
@admin_required
def list_resources():
    page = max(1, int(request.args.get('page', 1)))
    per_page = min(100, int(request.args.get('per_page', 20)))
    q = Resource.query.order_by(Resource.uploaded_at.desc())
    result = paginate_query(q, page, per_page, serialize_fn=lambda r: r.to_dict())
    return jsonify({'success': True, **result}), 200


@api_admin_bp.route('/resources', methods=['POST'])
@admin_required
def create_resource():
    title = file_path = file_name = file_type = file_size = None
    description = url = subject_id = None

    if request.is_json:
        data = request.get_json()
        title = (data.get('title') or '').strip()
        description = data.get('description') or None
        url = data.get('url') or None
        subject_id = data.get('subject_id') or None
    else:
        title = (request.form.get('title') or '').strip()
        description = request.form.get('description') or None
        url = request.form.get('url') or None
        subject_id = request.form.get('subject_id') or None

        if 'file' in request.files and request.files['file'].filename:
            file = request.files['file']
            if not allowed_file(file.filename):
                return error_response('File type not allowed', 422, 'INVALID_FILE_TYPE')
            fname = secure_filename(file.filename)
            save_path = os.path.join(current_app.config['UPLOAD_FOLDER'], fname)
            file.save(save_path)
            file_path = save_path
            file_name = fname
            file_type = file.mimetype
            file_size = os.path.getsize(save_path)

    if not title:
        return error_response('title is required', 422, 'VALIDATION_ERROR')

    r = Resource(title=title, description=description, subject_id=subject_id,
                 url=url, file_path=file_path, file_name=file_name,
                 file_type=file_type, file_size=file_size)
    db.session.add(r)
    db.session.commit()
    return jsonify({'success': True, 'data': r.to_dict()}), 201


@api_admin_bp.route('/resources/<int:resource_id>', methods=['DELETE'])
@admin_required
def delete_resource(resource_id):
    r = Resource.query.get_or_404(resource_id)
    if r.file_path and os.path.exists(r.file_path):
        os.remove(r.file_path)
    db.session.delete(r)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Resource deleted'}), 200


# ── Leaderboard settings ──────────────────────────────────────────────────────

@api_admin_bp.route('/leaderboard-settings', methods=['GET'])
@admin_required
def get_leaderboard_settings():
    import json
    settings = {
        'exam_types': json.loads(AppConfig.get('leaderboard_exam_types', '[]')),
        'subject_ids': json.loads(AppConfig.get('leaderboard_subject_ids', '[]')),
        'batch_filter': AppConfig.get('leaderboard_batch_filter', ''),
    }
    return jsonify({'success': True, 'data': settings}), 200


@api_admin_bp.route('/leaderboard-settings', methods=['PUT'])
@admin_required
def update_leaderboard_settings():
    import json
    data = request.get_json(silent=True) or {}
    if 'exam_types' in data:
        AppConfig.set('leaderboard_exam_types', json.dumps(data['exam_types']))
    if 'subject_ids' in data:
        AppConfig.set('leaderboard_subject_ids', json.dumps(data['subject_ids']))
    if 'batch_filter' in data:
        AppConfig.set('leaderboard_batch_filter', data['batch_filter'] or '')
    db.session.commit()
    return jsonify({'success': True, 'message': 'Settings updated'}), 200
