"""Run with:  python seed_data.py
Creates sample data — admin, students, subjects, marks, attendance, resources.
"""
import os
from datetime import date, datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

from app import create_app
from app.extensions import db
from app.models import Student, Admin, Subject, Mark, Attendance, Resource, UpcomingExam

app = create_app('development')

BATCHES = ['2025A', '2025B']
CENTERS = ['Colombo', 'Kandy']
SUBJECTS = [
    {'name': 'Combined Mathematics', 'code': 'CM'},
    {'name': 'Physics', 'code': 'PH'},
    {'name': 'Chemistry', 'code': 'CH'},
    {'name': 'Biology', 'code': 'BI'},
]
EXAM_TYPES = ['Paper 1', 'Paper 2', 'Mock', 'Term Test']


def seed():
    with app.app_context():
        db.drop_all()
        db.create_all()

        # Admin
        admin = Admin(username='admin', email='admin@maestro.lk', name='Admin User')
        admin.set_password('admin123')
        db.session.add(admin)

        # Subjects
        subjects = []
        for s_data in SUBJECTS:
            s = Subject(**s_data)
            db.session.add(s)
            subjects.append(s)
        db.session.flush()

        # Students (10 sample)
        import random
        random.seed(42)
        students = []
        for i in range(1, 11):
            batch = BATCHES[i % 2]
            center = CENTERS[i % 2]
            s = Student(
                index_number=f'2025{i:04d}',
                name=f'Student {i}',
                email=f'student{i}@example.com',
                phone=f'+94{70 + i}1234567',
                batch=batch,
                center=center,
            )
            s.set_password('student123')
            db.session.add(s)
            students.append(s)
        db.session.flush()

        # Marks
        for student in students:
            for subject in subjects:
                for exam_type in EXAM_TYPES[:2]:  # Paper 1 & Paper 2
                    mark_val = random.uniform(30, 95)
                    m = Mark(
                        student_id=student.id,
                        subject_id=subject.id,
                        exam_type=exam_type,
                        pack='Pack 1',
                        mark=round(mark_val, 1),
                        total_marks=100.0,
                        date=date(2025, random.randint(1, 6), random.randint(1, 28)),
                    )
                    db.session.add(m)

        # Attendance
        for student in students:
            for subject in subjects:
                for i in range(5):
                    a = Attendance(
                        student_id=student.id,
                        subject_id=subject.id,
                        session_name=f'Session {i + 1}',
                        exam_type='Paper 1',
                        date=date(2025, 3, i + 1),
                        is_present=random.random() > 0.15,
                    )
                    db.session.add(a)

        # Resources
        resources_data = [
            {'title': 'Combined Maths — Past Papers 2020-2024', 'subject_id': subjects[0].id,
             'url': 'https://example.com/cm-pastpapers', 'description': 'Full collection of A/L past papers'},
            {'title': 'Physics Formula Sheet', 'subject_id': subjects[1].id,
             'url': 'https://example.com/physics-formulas', 'description': 'Quick reference formula sheet'},
            {'title': 'Chemistry Notes — Organic', 'subject_id': subjects[2].id,
             'url': 'https://example.com/chem-organic'},
        ]
        for r_data in resources_data:
            db.session.add(Resource(**r_data))

        # Upcoming exams
        now = datetime.utcnow()
        upcoming_data = [
            {'title': 'Combined Maths Mock Exam', 'subject_id': subjects[0].id,
             'exam_type': 'Mock', 'exam_date': now + timedelta(days=14), 'batch': 'ALL'},
            {'title': 'Physics Paper 1', 'subject_id': subjects[1].id,
             'exam_type': 'Paper 1', 'exam_date': now + timedelta(days=30)},
            {'title': 'Mid-Term Chemistry Test', 'subject_id': subjects[2].id,
             'exam_type': 'Term Test', 'exam_date': now + timedelta(days=45)},
        ]
        for u_data in upcoming_data:
            db.session.add(UpcomingExam(**u_data))

        db.session.commit()
        print('✓ Seed complete.')
        print('  Admin:   admin / admin123')
        print('  Student: 20250001 / student123  (index_number / password)')
        print(f'  {len(students)} students, {len(subjects)} subjects seeded.')


if __name__ == '__main__':
    seed()
