helper = require 'lib/coursesHelper'
Campaigns = require 'collections/Campaigns'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
Classrooms = require 'collections/Classrooms'
Levels = require 'collections/Levels'
LevelSessions = require 'collections/LevelSessions'
factories = require 'test/app/factories'

describe 'CoursesHelper', ->

  describe 'calculateAllProgress', ->

    beforeEach ->
      # classrooms, courses, campaigns, courseInstances, students
      courses = _.times(1, -> factories.makeCourse())
      members = _.times(2, -> factories.makeUser())
      levels = _.times(2, -> factories.makeLevel())
      classroom = factories.makeClassroom({}, {courses, members, levels: [levels]})
      courseInstance = factories.makeCourseInstance({}, { course: courses[0], classroom, members })
      @classrooms = new Classrooms([ classroom ])
      @classroom = @classrooms.first()
      @courses = new Courses(courses)
      @course = @courses.first()
      @students = new Users(members)
      @levels = new Levels(levels)
      @courseInstances = new CourseInstances([courseInstance])

    describe 'when all students have completed a course', ->
      beforeEach ->
        sessions = []
        for level in @levels.models
          for student in @students.models
            sessions.push(factories.makeSession(
              {state: {complete: true}}, 
              {level: level.toJSON(), creator: student.toJSON()}
            ))
        @classroom.sessions = new LevelSessions(sessions)
      
      describe 'progressData.get({classroom, course})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          progress = progressData.get {@classroom, @course}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          for student in @students.models
            progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
            progress = progressData.get {@classroom, @course, user: student}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @levels.models
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'progressData.get({classroom, course, level, user})', ->
        it 'returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @levels.models
            for user in @students.models
              progress = progressData.get {@classroom, @course, level, user}
              expect(progress.completed).toBe true
              expect(progress.started).toBe true

    describe 'when NOT all students have completed a course', ->

      beforeEach ->
        sessions = []
        @finishedStudent = @students.first()
        @unfinishedStudent = @students.last()
        for level in @levels.models
          sessions.push(factories.makeSession(
            {state: {complete: true}}, 
            {level: level.toJSON(), creator: @finishedStudent.toJSON()})
          )
        sessions.push(factories.makeSession(
          {state: {complete: false}}, 
          {level: @levels.first().toJSON(), creator: @unfinishedStudent.toJSON()})
        )
        @classroom.sessions = new LevelSessions(sessions)

      it 'progressData.get({classroom, course}) returns object with .completed=false', ->
        progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
        progress = progressData.get {@classroom, @course}
        expect(progress.completed).toBe false

      describe 'when NOT all students have completed a level', ->
        it 'progressData.get({classroom, course, level}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @levels.models
            progress = progressData.get {@classroom, @course, level}
            expect(progress.completed).toBe false

      describe 'when the student has completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          progress = progressData.get {@classroom, @course, user: @finishedStudent}
          expect(progress.completed).toBe true
          expect(progress.started).toBe true

      describe 'when the student has NOT completed the course', ->
        it 'progressData.get({classroom, course, user}) returns object with .completed=false and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          progress = progressData.get {@classroom, @course, user: @unfinishedStudent}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has completed the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          for level in @levels.models
            progress = progressData.get {@classroom, @course, level, user: @finishedStudent}
            expect(progress.completed).toBe true
            expect(progress.started).toBe true

      describe 'when the student has NOT completed the level but has started', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=true and .started=true', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          level = @levels.first()
          progress = progressData.get {@classroom, @course, level, user: @unfinishedStudent}
          expect(progress.completed).toBe false
          expect(progress.started).toBe true

      describe 'when the student has NOT started the level', ->
        it 'progressData.get({classroom, course, level, user}) returns object with .completed=false and .started=false', ->
          progressData = helper.calculateAllProgress(@classrooms, @courses, @courseInstances, @students)
          level = @levels.last()
          progress = progressData.get {@classroom, @course, level, user: @unfinishedStudent}
          expect(progress.completed).toBe false
          expect(progress.started).toBe false
