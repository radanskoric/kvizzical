require "test_helper"
require "fileutils"
require "rake"
require "tmpdir"

class QuizImportTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("quiz:import")
    @task = Rake::Task["quiz:import"]
    @tmpdir = Dir.mktmpdir
  end

  teardown do
    @task.reenable
    FileUtils.remove_entry(@tmpdir)
  end

  test "imports a quiz from yaml using the filename as the title" do
    quiz_path = write_quiz_file("ruby_magic.yml", [
      {
        "question" => "What does `1 + 1` evaluate to?",
        "answers" => [ "1", "2", "3" ],
        "correct" => 1
      },
      {
        "question" => "What does `nil.nil?` return?",
        "answers" => [ "true", "false" ],
        "correct" => 0,
        "time_limit_seconds" => 20
      }
    ])

    _stdout, = capture_io do
      @task.invoke(quiz_path)
    end

    quiz = Quiz.find_by!(title: "Ruby Magic")

    assert_equal 2, quiz.questions.count
    assert_equal [ 1, 2 ], quiz.questions.pluck(:position)
    assert_equal [ 15, 20 ], quiz.questions.pluck(:time_limit_seconds)
    assert_equal [ false, true, false ], quiz.questions.first.answers.order(:id).pluck(:correct)
    assert_equal [ "1", "2", "3" ], quiz.questions.first.answers.order(:id).pluck(:body)
  end

  test "re-import replaces existing questions for the same filename-derived title" do
    quiz_path = write_quiz_file("ruby_magic.yml", [
      {
        "question" => "Old question?",
        "answers" => [ "No", "Yes" ],
        "correct" => 1
      }
    ])

    capture_io do
      @task.invoke(quiz_path)
    end

    quiz = Quiz.find_by!(title: "Ruby Magic")
    original_quiz_id = quiz.id
    original_question_id = quiz.questions.first.id

    @task.reenable
    write_quiz_file("ruby_magic.yml", [
      {
        "question" => "New question?",
        "answers" => [ "Maybe", "Definitely" ],
        "correct" => 0
      },
      {
        "question" => "Another question?",
        "answers" => [ "Left", "Right", "Center" ],
        "correct" => 2
      }
    ])

    capture_io do
      @task.invoke(quiz_path)
    end

    quiz.reload

    assert_equal original_quiz_id, quiz.id
    assert_equal 2, quiz.questions.count
    assert_equal [ "New question?", "Another question?" ], quiz.questions.pluck(:body)
    assert_not Question.exists?(original_question_id)
  end

  test "invalid yaml does not create or modify a quiz" do
    quiz_path = write_quiz_file("broken_quiz.yml", [
      {
        "question" => "Broken?",
        "answers" => [ "A", "B" ],
        "correct" => 3
      }
    ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 has an invalid correct answer index", error.message
    assert_nil Quiz.find_by(title: "Broken Quiz")
  end

  test "raises error when path argument is blank" do
    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke("")
      end
    end

    assert_equal "Usage: bin/rails quiz:import[path/to/file.yml]", error.message
  end

  test "raises error when file does not exist" do
    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke("/nonexistent/path/to/quiz.yml")
      end
    end

    assert_match(/Quiz file not found/, error.message)
  end

  test "raises error when yaml is not an array" do
    path = File.join(@tmpdir, "not_array.yml")
    File.write(path, { "question" => "Wrong structure" }.to_yaml)

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(path)
      end
    end

    assert_equal "Quiz file must contain a top-level array of questions", error.message
  end

  test "raises error when question entry is not a hash" do
    quiz_path = write_quiz_file("bad_entry.yml", [ "Not a hash" ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 must be a mapping", error.message
  end

  test "raises error when question text is blank" do
    quiz_path = write_quiz_file("blank_question.yml", [
      {
        "question" => "  ",
        "answers" => [ "A", "B" ],
        "correct" => 0
      }
    ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 is missing question text", error.message
  end

  test "raises error when answer text is blank" do
    quiz_path = write_quiz_file("blank_answer.yml", [
      {
        "question" => "Valid question?",
        "answers" => [ "Valid", "  " ],
        "correct" => 0
      }
    ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 has a blank answer", error.message
  end

  test "imports quiz using relative path" do
    quiz_path = write_quiz_file("relative_path.yml", [
      {
        "question" => "Test?",
        "answers" => [ "Yes", "No" ],
        "correct" => 0
      }
    ])

    FileUtils.cp(quiz_path, Rails.root.join("relative_path.yml"))

    begin
      capture_io do
        @task.invoke("relative_path.yml")
      end

      quiz = Quiz.find_by!(title: "Relative Path")
      assert_equal 1, quiz.questions.count
    ensure
      FileUtils.rm_f(Rails.root.join("relative_path.yml"))
    end
  end

  test "imports question bodies with multi-line code blocks preserving formatting" do
    question_body = <<~MARKDOWN
      What does this print?

      ```ruby
      def greet(name)
        puts "Hello, #{name}!"
      end

      greet("world")
      ```
    MARKDOWN

    quiz_path = write_quiz_file("code_blocks.yml", [
      {
        "question" => question_body,
        "answers" => [ "Hello, world!", "Hello, !" ],
        "correct" => 0
      }
    ])

    capture_io do
      @task.invoke(quiz_path)
    end

    quiz = Quiz.find_by!(title: "Code Blocks")

    assert_equal question_body, quiz.questions.first.body
  end

  test "imports references for a question" do
    quiz_path = write_quiz_file("references.yml", [
      {
        "question" => "What does MVC stand for?",
        "answers" => [ "Model-View-Controller", "Most Valuable Coder" ],
        "correct" => 0,
        "references" => [
          "https://guides.rubyonrails.org/action_controller_overview.html",
          "https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller"
        ]
      }
    ])

    capture_io do
      @task.invoke(quiz_path)
    end

    quiz = Quiz.find_by!(title: "References")

    assert_equal [
      "https://guides.rubyonrails.org/action_controller_overview.html",
      "https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller"
    ], quiz.questions.first.references.order(:id).pluck(:url)
  end

  test "raises error when references is not an array" do
    quiz_path = write_quiz_file("bad_references.yml", [
      {
        "question" => "What does MVC stand for?",
        "answers" => [ "Model-View-Controller", "Most Valuable Coder" ],
        "correct" => 0,
        "references" => "https://guides.rubyonrails.org/action_controller_overview.html"
      }
    ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 references must be an array", error.message
  end

  test "raises error when a reference is blank" do
    quiz_path = write_quiz_file("blank_reference.yml", [
      {
        "question" => "What does MVC stand for?",
        "answers" => [ "Model-View-Controller", "Most Valuable Coder" ],
        "correct" => 0,
        "references" => [ "  " ]
      }
    ])

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_equal "Question #1 has a blank reference", error.message
  end

  test "raises error when quiz has existing games" do
    quiz_path = write_quiz_file("with_games.yml", [
      {
        "question" => "First import?",
        "answers" => [ "Yes", "No" ],
        "correct" => 0
      }
    ])

    capture_io do
      @task.invoke(quiz_path)
    end

    quiz = Quiz.find_by!(title: "With Games")
    Game.create!(quiz: quiz)

    @task.reenable

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(quiz_path)
      end
    end

    assert_match(/has games/, error.message)
  end

  test "raises error when answers is not an array" do
    path = File.join(@tmpdir, "bad_answers.yml")
    File.write(path, [
      {
        "question" => "Test?",
        "answers" => "Not an array",
        "correct" => 0
      }
    ].to_yaml)

    error = assert_raises(ArgumentError) do
      capture_io do
        @task.invoke(path)
      end
    end

    assert_equal "Question #1 must have at least one answer", error.message
  end

  private

    def write_quiz_file(filename, payload)
      path = File.join(@tmpdir, filename)
      File.write(path, payload.to_yaml)
      path
    end
end
