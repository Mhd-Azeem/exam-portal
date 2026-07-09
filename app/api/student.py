from datetime import datetime
from functools import wraps
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from ..models import Student, Mark, Attendance, Resource, UpcomingExam, Subject
from ..extensions import db
from ..utils import error_response

api_student_bp = Blueprint('api_student', __name__)


def student_required(fn):
    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        if get_jwt().get('role') != 'student':
            return error_response('Student access required', 403, 'FORBIDDEN')
        return fn(*args, **kwargs)
    wrapper.__name__ = fn.__name__
    return wrapper


def _current_student():
    user_id = get_jwt().get('user_id')
    return Student.query.get(user_id)


# ── Profile ────────────────────────────────────────────────────────────────

@api_student_bp.route('/profile', methods=['GET'])
@student_required
def profile():
    student = _current_student()
    if not student:
        return error_response('Student not found', 404, 'NOT_FOUND')
    return jsonify({'success': True, 'data': student.to_dict()}), 200


# ── Dashboard summary ──────────────────────────────────────────────────────

@api_student_bp.route('/dashboard-summary', methods=['GET'])
@student_required
def dashboard_summary():
    student = _current_student()
    if not student:
        return error_response('Student not found', 404, 'NOT_FOUND')

    marks = student.marks.all()
    subjects_count = len(set(m.subject_id for m in marks))
    average_pct = student.get_average_percentage()
    highest_pct = student.get_highest_percentage()
    best_grade = student.get_best_grade()

    batch_students = Student.query.filter_by(batch=student.batch, is_active=True).all()
    batch_avgs = sorted(
        [(s.id, s.get_average_percentage()) for s in batch_students],
        key=lambda x: x[1], reverse=True,
    )
    batch_rank = next((i + 1 for i, (sid, _) in enumerate(batch_avgs) if sid == student.id), None)
    total_in_batch = len(batch_students)

    recent_marks = student.marks.filter(Mark.date != None).order_by(Mark.date.asc()).limit(10).all()
    recent_trend = [
        {
            'date': m.date.isoformat(),
            'subject': m.subject.name if m.subject else None,
            'exam_type': m.exam_type,
            'percentage': m.percentage,
            'grade': m.grade,
        }
        for m in recent_marks
    ]

    top_performer = None
    if batch_avgs:
        top_id, top_avg = batch_avgs[0]
        top_s = Student.query.get(top_id)
        if top_s:
            top_performer = {
                'id': top_s.id,
                'name': top_s.name,
                'index_number': top_s.index_number,
                'average_percentage': top_avg,
                'best_grade': top_s.get_best_grade(),
            }

    return jsonify({
        'success': True,
        'data': {
            'subjects_count': subjects_count,
            'average_percentage': average_pct,
            'highest_percentage': highest_pct,
            'best_grade': best_grade,
            'batch_rank': batch_rank,
            'total_in_batch': total_in_batch,
            'recent_trend': recent_trend,
            'top_performer': top_performer,
        },
    }), 200


# ── Upcoming exams ──────────────────────────────────────────────────────────

@api_student_bp.route('/upcoming-exams', methods=['GET'])
@student_required
def upcoming_exams():
    student = _current_student()
    now = datetime.utcnow()

    upcoming = UpcomingExam.query.filter(
        UpcomingExam.exam_date > now,
        UpcomingExam.is_active == True,
        db.or_(UpcomingExam.batch == None, UpcomingExam.batch == student.batch),
    ).order_by(UpcomingExam.exam_date.asc()).all()

    exams_data = []
    for exam in upcoming:
        d = exam.to_dict()
        d['days_until'] = (exam.exam_date - now).days
        exams_data.append(d)

    return jsonify({
        'success': True,
        'data': {
            'countdown_target': exams_data[0] if exams_data else None,
            'upcoming': exams_data,
        },
    }), 200


# ── Marks ──────────────────────────────────────────────────────────────────

@api_student_bp.route('/marks', methods=['GET'])
@student_required
def get_marks():
    student = _current_student()
    query = student.marks

    subject_id = request.args.get('subject')
    exam_type = request.args.get('exam_type')
    pack = request.args.get('pack')

    if subject_id:
        query = query.filter(Mark.subject_id == int(subject_id))
    if exam_type:
        query = query.filter(Mark.exam_type == exam_type)
    if pack:
        query = query.filter(Mark.pack == pack)

    marks = query.order_by(Mark.date.desc()).all()
    return jsonify({'success': True, 'data': [m.to_dict() for m in marks]}), 200


# ── Attendance ──────────────────────────────────────────────────────────────

@api_student_bp.route('/attendance', methods=['GET'])
@student_required
def get_attendance():
    student = _current_student()
    records = student.attendances.order_by(Attendance.date.desc()).all()
    total = len(records)
    present = sum(1 for a in records if a.is_present)
    percentage = round(present / total * 100, 2) if total > 0 else 0.0

    return jsonify({
        'success': True,
        'data': {
            'percentage': percentage,
            'total_sessions': total,
            'present_count': present,
            'absent_count': total - present,
            'records': [a.to_dict() for a in records],
        },
    }), 200


# ── Leaderboard ─────────────────────────────────────────────────────────────

@api_student_bp.route('/leaderboard', methods=['GET'])
@student_required
def get_leaderboard():
    student = _current_student()

    if student.batch:
        all_students = Student.query.filter_by(batch=student.batch, is_active=True).all()
    else:
        all_students = Student.query.filter_by(is_active=True).all()

    board = sorted(
        [
            {
                'id': s.id,
                'name': s.name,
                'index_number': s.index_number,
                'batch': s.batch,
                'center': s.center,
                'average_percentage': s.get_average_percentage(),
                'best_grade': s.get_best_grade(),
                'is_current_user': s.id == student.id,
            }
            for s in all_students
        ],
        key=lambda x: x['average_percentage'],
        reverse=True,
    )
    for i, entry in enumerate(board):
        entry['rank'] = i + 1

    top_performer = board[0] if board else None
    current_rank = next((e for e in board if e['is_current_user']), None)

    return jsonify({
        'success': True,
        'data': {
            'top_performer': top_performer,
            'current_user_rank': current_rank,
            'leaderboard': board,
        },
    }), 200


# ── Resources ───────────────────────────────────────────────────────────────

@api_student_bp.route('/resources', methods=['GET'])
@student_required
def get_resources():
    subject_id = request.args.get('subject')
    query = Resource.query
    if subject_id:
        query = query.filter(Resource.subject_id == int(subject_id))
    resources = query.order_by(Resource.uploaded_at.desc()).all()
    return jsonify({'success': True, 'data': [r.to_dict() for r in resources]}), 200
