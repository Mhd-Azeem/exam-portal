from datetime import datetime
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from .extensions import db


def calculate_grade(percentage):
    """Sri Lanka A/L grade scale."""
    if percentage >= 75:
        return 'A'
    elif percentage >= 65:
        return 'B'
    elif percentage >= 55:
        return 'C'
    elif percentage >= 35:
        return 'S'
    else:
        return 'F'


class Student(db.Model, UserMixin):
    __tablename__ = 'students'

    id = db.Column(db.Integer, primary_key=True)
    index_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True)
    phone = db.Column(db.String(20))
    batch = db.Column(db.String(50), index=True)
    center = db.Column(db.String(100), index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    marks = db.relationship('Mark', backref='student', lazy='dynamic', cascade='all, delete-orphan')
    attendances = db.relationship('Attendance', backref='student', lazy='dynamic', cascade='all, delete-orphan')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def get_average_percentage(self):
        all_marks = self.marks.all()
        if not all_marks:
            return 0.0
        total = sum(m.percentage for m in all_marks)
        return round(total / len(all_marks), 2)

    def get_highest_percentage(self):
        all_marks = self.marks.all()
        if not all_marks:
            return 0.0
        return round(max(m.percentage for m in all_marks), 2)

    def get_best_grade(self):
        return calculate_grade(self.get_highest_percentage())

    def to_dict(self):
        return {
            'id': self.id,
            'index_number': self.index_number,
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'batch': self.batch,
            'center': self.center,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def to_dict_with_stats(self):
        d = self.to_dict()
        d['average_percentage'] = self.get_average_percentage()
        d['highest_percentage'] = self.get_highest_percentage()
        d['best_grade'] = self.get_best_grade()
        return d


class Admin(db.Model):
    __tablename__ = 'admins'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True)
    name = db.Column(db.String(100))
    password_hash = db.Column(db.String(255), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'name': self.name,
            'is_active': self.is_active,
        }


class Subject(db.Model):
    __tablename__ = 'subjects'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(20))
    description = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    marks = db.relationship('Mark', backref='subject', lazy='dynamic', cascade='all, delete-orphan')
    attendances = db.relationship('Attendance', backref='subject', lazy='dynamic', cascade='all, delete-orphan')
    resources = db.relationship('Resource', backref='subject', lazy='dynamic')
    upcoming_exams = db.relationship('UpcomingExam', backref='subject', lazy='dynamic')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'code': self.code,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Mark(db.Model):
    __tablename__ = 'marks'

    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('students.id'), nullable=False, index=True)
    subject_id = db.Column(db.Integer, db.ForeignKey('subjects.id'), nullable=False, index=True)
    exam_type = db.Column(db.String(50))
    pack = db.Column(db.String(50))
    mark = db.Column(db.Float, nullable=False)
    total_marks = db.Column(db.Float, default=100.0)
    date = db.Column(db.Date)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    @property
    def percentage(self):
        if self.total_marks and self.total_marks > 0:
            return round(self.mark / self.total_marks * 100, 2)
        return 0.0

    @property
    def grade(self):
        return calculate_grade(self.percentage)

    def to_dict(self):
        return {
            'id': self.id,
            'student_id': self.student_id,
            'student_name': self.student.name if self.student else None,
            'student_index': self.student.index_number if self.student else None,
            'subject_id': self.subject_id,
            'subject_name': self.subject.name if self.subject else None,
            'exam_type': self.exam_type,
            'pack': self.pack,
            'mark': self.mark,
            'total_marks': self.total_marks,
            'percentage': self.percentage,
            'grade': self.grade,
            'date': self.date.isoformat() if self.date else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Attendance(db.Model):
    __tablename__ = 'attendances'

    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('students.id'), nullable=False, index=True)
    subject_id = db.Column(db.Integer, db.ForeignKey('subjects.id'), nullable=False, index=True)
    session_name = db.Column(db.String(100))
    exam_type = db.Column(db.String(50))
    date = db.Column(db.Date)
    is_present = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'student_id': self.student_id,
            'student_name': self.student.name if self.student else None,
            'student_index': self.student.index_number if self.student else None,
            'subject_id': self.subject_id,
            'subject_name': self.subject.name if self.subject else None,
            'session_name': self.session_name,
            'exam_type': self.exam_type,
            'date': self.date.isoformat() if self.date else None,
            'is_present': self.is_present,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Resource(db.Model):
    __tablename__ = 'resources'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    file_path = db.Column(db.String(500))
    file_name = db.Column(db.String(255))
    file_type = db.Column(db.String(100))
    file_size = db.Column(db.Integer)
    subject_id = db.Column(db.Integer, db.ForeignKey('subjects.id'))
    url = db.Column(db.String(500))
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'file_name': self.file_name,
            'file_type': self.file_type,
            'file_size': self.file_size,
            'subject_id': self.subject_id,
            'subject_name': self.subject.name if self.subject else None,
            'url': self.url,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }


class UpcomingExam(db.Model):
    __tablename__ = 'upcoming_exams'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    subject_id = db.Column(db.Integer, db.ForeignKey('subjects.id'))
    exam_type = db.Column(db.String(50))
    exam_date = db.Column(db.DateTime)
    description = db.Column(db.Text)
    batch = db.Column(db.String(50))
    center = db.Column(db.String(100))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'subject_id': self.subject_id,
            'subject_name': self.subject.name if self.subject else None,
            'exam_type': self.exam_type,
            'exam_date': self.exam_date.isoformat() if self.exam_date else None,
            'description': self.description,
            'batch': self.batch,
            'center': self.center,
            'is_active': self.is_active,
        }


class AppConfig(db.Model):
    __tablename__ = 'app_configs'

    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(100), unique=True, nullable=False)
    value = db.Column(db.Text)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    @classmethod
    def get(cls, key, default=None):
        row = cls.query.filter_by(key=key).first()
        return row.value if row else default

    @classmethod
    def set(cls, key, value):
        row = cls.query.filter_by(key=key).first()
        if row:
            row.value = value
            row.updated_at = datetime.utcnow()
        else:
            row = cls(key=key, value=value)
            db.session.add(row)
