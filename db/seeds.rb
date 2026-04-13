# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

quiz = Quiz.find_or_create_by!(title: "Ruby & Rails Trivia")

questions_data = [
  {
    body: "What does MVC stand for?",
    time_limit_seconds: 15,
    answers: [
      { body: "Model-View-Controller", correct: true },
      { body: "Most Valuable Coder", correct: false },
      { body: "Multiple Virtual Connections", correct: false },
      { body: "Main Visual Component", correct: false }
    ]
  },
  {
    body: "Which command starts a Rails console?",
    time_limit_seconds: 15,
    answers: [
      { body: "bin/rails console", correct: true },
      { body: "bin/rails start", correct: false },
      { body: "ruby console", correct: false },
      { body: "bundle exec irb", correct: false }
    ]
  },
  {
    body: "What is the default database for a new Rails 8 app?",
    time_limit_seconds: 15,
    answers: [
      { body: "SQLite3", correct: true },
      { body: "PostgreSQL", correct: false },
      { body: "MySQL", correct: false },
      { body: "MongoDB", correct: false }
    ]
  },
  {
    body: "Which Ruby keyword defines a block that always executes?",
    time_limit_seconds: 15,
    answers: [
      { body: "ensure", correct: true },
      { body: "finally", correct: false },
      { body: "always", correct: false },
      { body: "rescue", correct: false }
    ]
  },
  {
    body: "What does 'DRY' stand for in software development?",
    time_limit_seconds: 15,
    answers: [
      { body: "Don't Repeat Yourself", correct: true },
      { body: "Do Rewrite Yearly", correct: false },
      { body: "Data Runs Yielded", correct: false },
      { body: "Deploy, Refactor, Yolo", correct: false }
    ]
  },
  {
    body: "Which Hotwire library intercepts links and form submissions?",
    time_limit_seconds: 15,
    answers: [
      { body: "Turbo Drive", correct: true },
      { body: "Stimulus", correct: false },
      { body: "Turbo Frames", correct: false },
      { body: "ActionCable", correct: false }
    ]
  },
  {
    body: "What symbol is used for string interpolation in Ruby?",
    time_limit_seconds: 15,
    answers: [
      { body: '#{...}', correct: true },
      { body: "${...}", correct: false },
      { body: "%{...}", correct: false },
      { body: "@{...}", correct: false }
    ]
  },
  {
    body: "Which method makes an ActiveRecord query lazy?",
    time_limit_seconds: 15,
    answers: [
      { body: "where", correct: true },
      { body: "find", correct: false },
      { body: "first", correct: false },
      { body: "count", correct: false }
    ]
  }
]

questions_data.each_with_index do |q_data, index|
  question = quiz.questions.find_or_create_by!(body: q_data[:body]) do |q|
    q.time_limit_seconds = q_data[:time_limit_seconds]
    q.position = index + 1
  end

  q_data[:answers].each do |a_data|
    question.answers.find_or_create_by!(body: a_data[:body]) do |a|
      a.correct = a_data[:correct]
    end
  end
end

game = Game.find_or_create_by!(quiz: quiz, code: "DEMO01")

puts "Seeded quiz '#{quiz.title}' with #{quiz.questions.count} questions"
puts "Game code: #{game.code}"
