import os
from datetime import datetime
from functools import wraps
from flask import Blueprint, render_template, redirect, url_for, request, flash, session, current_app
from werkzeug.utils import secure_filename
from ..models import Student, Admin, Subject, Mark, Attendance, Resource, UpcomingExam
from ..extensions import db
from ..utils import allowed_file

web_admin_bp = Blueprint('web_admin', __name__)


def admin_login_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if not session.get('admin_id'):
            return redirect(url_for('web_auth.admin_login'))
        return fn(*args, **kwargs)
    wrapper.__name__ = fn.__name__
    return wrapper


# ── Overview ────────────────────────────────────────────────────────────────

@web_admin_bp.route('/')
@web_admin_bp.route('/dashboard')
@admin_login_required
def dashboard():
    batch = request.args.get('batch')
    center = request.args.get('center')

    q = Student.query.filter_by(is_active=True)
    if batch:
        q = q.filter_by(batch=batch)
    if center:
        q = q.filter_by(center=center)
    students = q.all()
    student_ids = [s.id for s in students]

    marks_q = Mark.query.filter(Mark.student_id.in_(student_ids)) if student_ids else Mark.query.filter(False)
    all_marks = marks_q.all()

    grade_dist = {'A': 0, 'B': 0, 'C': 0, 'S': 0, 'F': 0}
    for m in all_marks:
        grade_dist[m.grade] = grade_dist.get(m.grade, 0) + 1

    overall_avg = round(sum(m.percentage for m in all_marks) / len(all_marks), 2) if all_marks else 0.0

    top_scorer = None
    if students:
        top_s = max(students, key=lambda s: s.get_average_percentage())
        top_scorer = top_s

    batches = [b[0] for b in db.session.query(Student.batch).distinct().filter(Student.batch != None).all()]
    centers = [c[0] for c in db.session.query(Student.center).distinct().filter(Student.center != None).all()]

    return render_template('admin/dashboard.html',
                           total_students=len(students),
                           total_subjects=Subject.query.count(),
                           total_marks=len(all_marks),
                           overall_avg=overall_avg,
                           grade_dist=grade_dist,
                           top_scorer=top_scorer,
                           batches=batches, centers=centers,
                           sel_batch=batch, sel_center=center)


# ── Students ─────────────────────────────────────────────────────────────────

@web_admin_bp.route('/students')
@admin_login_required
def students():
    search = request.args.get('q', '')
    batch = request.args.get('batch')
    center = request.args.get('center')
    page = int(request.args.get('page', 1))

    q = Student.query
    if search:
        q = q.filter(db.or_(Student.name.ilike(f'%{search}%'), Student.index_number.ilike(f'%{search}%')))
    if batch:
        q = q.filter_by(batch=batch)
    if center:
        q = q.filter_by(center=center)

    pagination = q.order_by(Student.name).paginate(page=page, per_page=20, error_out=False)
    batches = [b[0] for b in db.session.query(Student.batch).distinct().filter(Student.batch != None).all()]
    centers = [c[0] for c in db.session.query(Student.center).distinct().filter(Student.center != None).all()]

    return render_template('admin/students.html', pagination=pagination,
                           search=search, batches=batches, centers=centers,
                           sel_batch=batch, sel_center=center)


@web_admin_bp.route('/students/new', methods=['GET', 'POST'])
@admin_login_required
def new_student():
    if request.method == 'POST':
        s = Student(
            index_number=request.form['index_number'],
            name=request.form['name'],
            email=request.form.get('email') or None,
            phone=request.form.get('phone') or None,
            batch=request.form.get('batch') or None,
            center=request.form.get('center') or None,
        )
        s.set_password(request.form['password'])
        db.session.add(s)
        try:
            db.session.commit()
            flash('Student created.', 'success')
            return redirect(url_for('web_admin.students'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}', 'danger')
    return render_template('admin/student_form.html', student=None)


@web_admin_bp.route('/students/<int:student_id>/edit', methods=['GET', 'POST'])
@admin_login_required
def edit_student(student_id):
    student = Student.query.get_or_404(student_id)
    if request.method == 'POST':
        student.name = request.form['name']
        student.email = request.form.get('email') or None
        student.phone = request.form.get('phone') or None
        student.batch = request.form.get('batch') or None
        student.center = request.form.get('center') or None
        if request.form.get('password'):
            student.set_password(request.form['password'])
        try:
            db.session.commit()
            flash('Student updated.', 'success')
            return redirect(url_for('web_admin.students'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}', 'danger')
    return render_template('admin/student_form.html', student=student)


@web_admin_bp.route('/students/<int:student_id>/delete', methods=['POST'])
@admin_login_required
def delete_student(student_id):
    student = Student.query.get_or_404(student_id)
    db.session.delete(student)
    db.session.commit()
    flash('Student deleted.', 'success')
    return redirect(url_for('web_admin.students'))


# ── Subjects ─────────────────────────────────────────────────────────────────

@web_admin_bp.route('/subjects')
@admin_login_required
def subjects():
    all_subjects = Subject.query.order_by(Subject.name).all()
    return render_template('admin/subjects.html', subjects=all_subjects)


@web_admin_bp.route('/subjects/new', methods=['POST'])
@admin_login_required
def new_subject():
    subj = Subject(name=request.form['name'], code=request.form.get('code'), description=request.form.get('description'))
    db.session.add(subj)
    db.session.commit()
    flash('Subject created.', 'success')
    return redirect(url_for('web_admin.subjects'))


@web_admin_bp.route('/subjects/<int:subject_id>/edit', methods=['POST'])
@admin_login_required
def edit_subject(subject_id):
    subj = Subject.query.get_or_404(subject_id)
    subj.name = request.form['name']
    subj.code = request.form.get('code')
    subj.description = request.form.get('description')
    db.session.commit()
    flash('Subject updated.', 'success')
    return redirect(url_for('web_admin.subjects'))


@web_admin_bp.route('/subjects/<int:subject_id>/delete', methods=['POST'])
@admin_login_required
def delete_subject(subject_id):
    subj = Subject.query.get_or_404(subject_id)
    db.session.delete(subj)
    db.session.commit()
    flash('Subject deleted.', 'success')
    return redirect(url_for('web_admin.subjects'))


# ── Marks ─────────────────────────────────────────────────────────────────────

@web_admin_bp.route('/marks')
@admin_login_required
def marks():
    page = int(request.args.get('page', 1))
    student_id = request.args.get('student_id')
    subject_id = request.args.get('subject_id')
    exam_type = request.args.get('exam_type')

    q = Mark.query
    if student_id:
        q = q.filter_by(student_id=int(student_id))
    if subject_id:
        q = q.filter_by(subject_id=int(subject_id))
    if exam_type:
        q = q.filter_by(exam_type=exam_type)

    pagination = q.order_by(Mark.date.desc()).paginate(page=page, per_page=30, error_out=False)
    subjects = Subject.query.order_by(Subject.name).all()
    students = Student.query.filter_by(is_active=True).order_by(Student.name).all()
    return render_template('admin/marks.html', pagination=pagination,
                           subjects=subjects, students=students,
                           sel_student=student_id, sel_subject=subject_id, sel_type=exam_type)


@web_admin_bp.route('/marks/add', methods=['POST'])
@admin_login_required
def add_mark():
    from ..utils import parse_date, validate_mark_value
    m_val, err = validate_mark_value(request.form.get('mark'), request.form.get('total_marks', 100))
    if err:
        flash(err, 'danger')
        return redirect(url_for('web_admin.marks'))
    m = Mark(
        student_id=int(request.form['student_id']),
        subject_id=int(request.form['subject_id']),
        exam_type=request.form.get('exam_type') or None,
        pack=request.form.get('pack') or None,
        mark=m_val,
        total_marks=float(request.form.get('total_marks', 100)),
        date=parse_date(request.form.get('date')),
    )
    db.session.add(m)
    db.session.commit()
    flash('Mark added.', 'success')
    return redirect(url_for('web_admin.marks'))


@web_admin_bp.route('/marks/<int:mark_id>/delete', methods=['POST'])
@admin_login_required
def delete_mark(mark_id):
    m = Mark.query.get_or_404(mark_id)
    db.session.delete(m)
    db.session.commit()
    flash('Mark deleted.', 'success')
    return redirect(url_for('web_admin.marks'))


# ── Attendance ───────────────────────────────────────────────────────────────

@web_admin_bp.route('/attendance')
@admin_login_required
def attendance():
    page = int(request.args.get('page', 1))
    subject_id = request.args.get('subject_id')
    q = Attendance.query
    if subject_id:
        q = q.filter_by(subject_id=int(subject_id))
    pagination = q.order_by(Attendance.date.desc()).paginate(page=page, per_page=30, error_out=False)
    subjects = Subject.query.order_by(Subject.name).all()
    students = Student.query.filter_by(is_active=True).order_by(Student.name).all()
    return render_template('admin/attendance.html', pagination=pagination,
                           subjects=subjects, students=students, sel_subject=subject_id)


@web_admin_bp.route('/attendance/add', methods=['POST'])
@admin_login_required
def add_attendance():
    from ..utils import parse_date
    a = Attendance(
        student_id=int(request.form['student_id']),
        subject_id=int(request.form['subject_id']),
        session_name=request.form.get('session_name') or None,
        exam_type=request.form.get('exam_type') or None,
        date=parse_date(request.form.get('date')),
        is_present=request.form.get('is_present') == 'true',
    )
    db.session.add(a)
    db.session.commit()
    flash('Attendance recorded.', 'success')
    return redirect(url_for('web_admin.attendance'))


# ── Resources ────────────────────────────────────────────────────────────────

@web_admin_bp.route('/resources')
@admin_login_required
def resources():
    resources_list = Resource.query.order_by(Resource.uploaded_at.desc()).all()
    subjects = Subject.query.order_by(Subject.name).all()
    return render_template('admin/resources.html', resources=resources_list, subjects=subjects)


@web_admin_bp.route('/resources/upload', methods=['POST'])
@admin_login_required
def upload_resource():
    title = request.form.get('title')
    if not title:
        flash('Title is required.', 'danger')
        return redirect(url_for('web_admin.resources'))

    subject_id = request.form.get('subject_id') or None
    description = request.form.get('description') or None
    url = request.form.get('url') or None
    file_path = file_name = file_type = file_size = None

    if 'file' in request.files and request.files['file'].filename:
        file = request.files['file']
        if not allowed_file(file.filename):
            flash('File type not allowed.', 'danger')
            return redirect(url_for('web_admin.resources'))
        fname = secure_filename(file.filename)
        save_path = os.path.join(current_app.config['UPLOAD_FOLDER'], fname)
        file.save(save_path)
        file_path = save_path
        file_name = fname
        file_type = file.mimetype
        file_size = os.path.getsize(save_path)

    r = Resource(title=title, description=description, subject_id=subject_id,
                 url=url, file_path=file_path, file_name=file_name,
                 file_type=file_type, file_size=file_size)
    db.session.add(r)
    db.session.commit()
    flash('Resource uploaded.', 'success')
    return redirect(url_for('web_admin.resources'))


@web_admin_bp.route('/resources/<int:resource_id>/delete', methods=['POST'])
@admin_login_required
def delete_resource(resource_id):
    r = Resource.query.get_or_404(resource_id)
    if r.file_path and os.path.exists(r.file_path):
        os.remove(r.file_path)
    db.session.delete(r)
    db.session.commit()
    flash('Resource deleted.', 'success')
    return redirect(url_for('web_admin.resources'))


# ── Leaderboard ──────────────────────────────────────────────────────────────

@web_admin_bp.route('/leaderboard')
@admin_login_required
def leaderboard():
    batch = request.args.get('batch')
    q = Student.query.filter_by(is_active=True)
    if batch:
        q = q.filter_by(batch=batch)
    students = q.all()
    board = sorted(
        [{'student': s, 'avg': s.get_average_percentage()} for s in students],
        key=lambda x: x['avg'], reverse=True
    )
    for i, e in enumerate(board):
        e['rank'] = i + 1
    batches = [b[0] for b in db.session.query(Student.batch).distinct().filter(Student.batch != None).all()]
    return render_template('admin/leaderboard.html', board=board, batches=batches, sel_batch=batch)
