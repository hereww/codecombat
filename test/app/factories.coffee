
module.exports = {

  makeCourse: (data, sources={}) ->
    _id = _.uniqueId('course_')
    data = _.extend({}, {
      _id: _id
      name: _.string.titleize(_id)
    }, data)
    
    data.campaignID ?= sources.campaign?._id or _.uniqueId('campaign_')
    return data
  
  makeLevel: (data) ->
    _id = _.uniqueId('level_')
    data = _.extend({}, {
      _id: _id
      name: _.string.titleize(_id)
      original: _id+'_original'
      version:
        major: 0
        minor: 0
        isLatestMajor: true
        isLatestMinor: true
    }, data)
    return data
  
  makeUser: (data) ->
    _id = _.uniqueId('user_')
    data = _.extend({
      _id: _id
      permissions: []
      email: _id+'@email.com'
      anonymous: false
    }, data)
    return data
  
  makeClassroom: (data, sources) ->
    sources = _.extend({}, {
      courses: 2
      members: 2
      levels: 2
    }, sources)
  
    _id = _.uniqueId('classroom_')
    data = _.extend({}, {
      _id: _id,
      name: _.string.titleize(_id)
      aceConfig: { language: 'python' }
    }, data)
  
    # populate courses
    if not data.courses
      courses = if _.isNumber(sources.courses) then (@makeCourse() for i in _.range(sources.courses)) else sources.courses
      data.courses = (_.pick(course, '_id') for course in courses)
  
    # populate levels in courses
    if _.isNumber(sources.levels)
      sources.levels = (sources.levels for i in _.range(sources.levels))
  
    for [course, levels] in _.zip(data.courses, sources.levels)
      course ?= @makeCourse()
      levels ?= 2
      levels = if _.isNumber(levels) then (@makeLevel() for i in _.range(levels)) else levels
      course.levels = (_.pick(level, '_id', 'slug', 'name', 'original', 'type') for level in levels)
  
    # populate members
    if not data.members
      members = if _.isNumber(sources.members) then (@makeUser() for i in _.range(sources.members)) else sources.members
      data.members = (member._id for member in members)
  
    return data
  
  makeSession: (data, sources={}) ->
    level = sources.level or @makeLevel()
    creator = sources.creator or @makeUser()
    data = _.extend({}, {
      level:
        original: level.original,
      creator: creator._id,
    }, data)
    return data
  
  makeCourseInstance: (data, sources={}) ->
    course = sources.course or @makeCourse()
    classroom = sources.classroom or @makeClassroom()
    owner = sources.owner or @makeUser()
    sources.members ?= 2
    members = if _.isNumber(sources.members) then (@makeUser() for i in _.range(sources.members)) else sources.members
    data = _.extend({}, {
      courseID: course._id
      classroomID: classroom._id
      ownerID: owner._id
      members: (member._id for member in members)
    }, data)
    return data

} 
  

