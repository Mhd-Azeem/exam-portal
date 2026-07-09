from flask import Blueprint, render_template, redirect, url_for, request, flash, session
from flask_login import login_user, logout_user, login_required, current_user
from ..models import Student, Admin

web_auth_bp = Blueprint('web_auth', __name__)


@web_auth_bp.route('/')
def index():
    return redirect(url_for('web_auth.login'))


@web_auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('web_student.dashboard'))
    if request.method == 'POST':
        index_number = request.form.get('index_number', '').strip()
        password = request.form.get('password', '')
        student = Student.query.filter_by(index_number=index_number, is_active=True).first()
        if student and student.check_password(password):
            login_user(student, remember=True)
            return redirect(url_for('web_student.dashboard'))
        flash('Invalid index number or password.', 'danger')
    return render_template('auth/login.html')


@web_auth_bp.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('web_auth.login'))


@web_auth_bp.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if session.get('admin_id'):
        return redirect(url_for('web_admin.dashboard'))
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        admin = Admin.query.filter_by(username=username, is_active=True).first()
        if admin and admin.check_password(password):
            session['admin_id'] = admin.id
            session['admin_name'] = admin.name or admin.username
            return redirect(url_for('web_admin.dashboard'))
        flash('Invalid username or password.', 'danger')
    return render_template('auth/admin_login.html')


@web_auth_bp.route('/admin/logout')
def admin_logout():
    session.pop('admin_id', None)
    session.pop('admin_name', None)
    return redirect(url_for('web_auth.admin_login'))
