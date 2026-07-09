from datetime import datetime
from flask import Blueprint, render_template, redirect, url_for
from flask_login import login_required, current_user
from ..models import Mark, Attendance, Resource, UpcomingExam, Student

web_student_bp = Blueprint('web_student', __name__)


@web_student_bp.route('/dashboard')
@login_required
def dashboard():
    student = current_user
    marks = student.marks.all()
    subjects_count = len(set(m.subject_id for m in marks))
    average_pct = student.get_average_percentage()
    highest_pct = student.get_highest_percentage()
    best_grade = student.get_best_grade()

    batch_students = Student.query.filter_by(batch=student.batch, is_active=True).all()
    batch_avgs = sorted(
        [(s.id, s.get_average_percentage()) for s in batch_students],
        key=lambda x: x[1], reverse=True
    )
    batch_rank = next((i + 1 for i, (sid, _) in enumerate(batch_avgs) if sid == student.id), '-')
    total_in_batch = len(batch_students)

    now = datetime.utcnow()
    upcoming = UpcomingExam.query.filter(
        UpcomingExam.exam_date > now,
        UpcomingExam.is_active == True,
    ).order_by(UpcomingExam.exam_date.asc()).limit(5).all()

    recent_marks = student.marks.order_by(Mark.date.desc()).limit(10).all()

    return render_template('student/dashboard.html',
                           student=student,
                           subjects_count=subjects_count,
                           average_pct=average_pct,
                           highest_pct=highest_pct,
                           best_grade=best_grade,
                           batch_rank=batch_rank,
                           total_in_batch=total_in_batch,
                           upcoming=upcoming,
                           recent_marks=recent_marks)


@web_student_bp.route('/marks')
@login_required
def marks():
    from flask import request
    from ..models import Subject
    subject_id = request.args.get('subject')
    exam_type = request.args.get('exam_type')
    pack = request.args.get('pack')

    query = current_user.marks
    if subject_id:
        query = query.filter(Mark.subject_id == int(subject_id))
    if exam_type:
        query = query.filter(Mark.exam_type == exam_type)
    if pack:
        query = query.filter(Mark.pack == pack)

    marks_list = query.order_by(Mark.date.desc()).all()
    subjects = Subject.query.all()
    return render_template('student/marks.html', marks=marks_list, subjects=subjects,
                           selected_subject=subject_id, selected_type=exam_type, selected_pack=pack)


@web_student_bp.route('/attendance')
@login_required
def attendance():
    records = current_user.attendances.order_by(Attendance.date.desc()).all()
    total = len(records)
    present = sum(1 for a in records if a.is_present)
    pct = round(present / total * 100, 1) if total else 0
    return render_template('student/attendance.html', records=records, total=total,
                           present=present, absent=total - present, pct=pct)


@web_student_bp.route('/leaderboard')
@login_required
def leaderboard():
    student = current_user
    if student.batch:
        all_students = Student.query.filter_by(batch=student.batch, is_active=True).all()
    else:
        all_students = Student.query.filter_by(is_active=True).all()

    board = sorted(
        [{'student': s, 'avg': s.get_average_percentage()} for s in all_students],
        key=lambda x: x['avg'], reverse=True
    )
    for i, entry in enumerate(board):
        entry['rank'] = i + 1

    return render_template('student/leaderboard.html', board=board, current_student=student)


@web_student_bp.route('/resources')
@login_required
def resources():
    from ..models import Subject
    resources_list = Resource.query.order_by(Resource.uploaded_at.desc()).all()
    subjects = Subject.query.all()
    return render_template('student/resources.html', resources=resources_list, subjects=subjects)
