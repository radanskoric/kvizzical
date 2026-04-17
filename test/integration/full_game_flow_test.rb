require "test_helper"

class FullGameFlowTest < ActionDispatch::IntegrationTest
  test "complete game lifecycle: join, start, answer, advance, finish" do
    game = games(:waiting_game)
    question1 = game.quiz.questions.order(:position).first
    question2 = game.quiz.questions.order(:position).second

    # Player joins via home page
    get root_path
    assert_response :success

    # Player navigates to game
    get play_path(code: game.code)
    assert_response :success

    # Player submits name
    post play_path(code: game.code), params: { name: "E2EPlayer" }
    assert_redirected_to play_path(code: game.code)
    follow_redirect!
    assert_response :success

    # Player sees waiting state
    assert_select "[data-game-status='waiting']"

    # Host starts the game
    sign_in_as(users(:alice))
    post start_game_path(game)
    assert_redirected_to game_path(game)
    game.reload
    assert game.active?
    assert_equal question1, game.current_question

    sign_out

    # Player sees question
    get play_path(code: game.code)
    assert_select "[data-question-body]", text: question1.body

    # Player submits correct answer
    correct_answer = question1.answers.find_by(correct: true)
    post responses_path, params: {
      game_code: game.code,
      question_id: question1.id,
      answer_id: correct_answer.id
    }
    assert_redirected_to play_path(code: game.code)

    # Verify response was created with a score
    user = User.find_by(session_token: session[:user_session_token])
    participant = game.participants.find_by(user: user)
    response = participant.responses.find_by(question: question1)
    assert response.present?
    assert response.score > 0

    # Player sees submitted confirmation
    follow_redirect!
    assert_response :success

    # Host finishes the question, then advances
    sign_in_as(users(:alice))
    post finish_question_game_path(game)
    game.reload
    assert game.reviewing?

    post advance_game_path(game)
    assert_redirected_to game_path(game)
    game.reload
    assert game.active?
    assert_equal question2, game.current_question

    sign_out

    # Player sees new question
    get play_path(code: game.code)
    assert_select "[data-question-body]", text: question2.body

    # Finish and advance through remaining questions
    loop do
      game.reload
      break if game.finished?
      if game.active?
        sign_in_as(users(:alice))
        post finish_question_game_path(game)
        sign_out
      elsif game.reviewing?
        sign_in_as(users(:alice))
        post advance_game_path(game)
        sign_out
      end
    end
    assert game.finished?

    # Host sees game over
    sign_in_as(users(:alice))
    get game_path(game)
    assert_select "[data-leaderboard]"

    sign_out

    # Player sees game over with leaderboard
    get play_path(code: game.code)
    assert_select "[data-game-status='finished']"
    assert_select "[data-leaderboard]"
  end

  test "player review screen shows references for the current question" do
    game = games(:active_game)
    question = game.current_question
    question.references.create!(url: "https://guides.rubyonrails.org/action_controller_overview.html")
    question.references.create!(url: "https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller")

    post play_path(code: game.code), params: { name: "Reference Player" }
    participant = game.participants.find_by!(user: User.find_by!(session_token: session[:user_session_token]))
    correct_answer = question.answers.find_by!(correct: true)

    post responses_path, params: {
      game_code: game.code,
      question_id: question.id,
      answer_id: correct_answer.id
    }

    sign_in_as(users(:alice))
    post finish_question_game_path(game)
    sign_out

    get play_path(code: game.code)

    assert_select "details", text: /References/
    assert_select "a[href='https://guides.rubyonrails.org/action_controller_overview.html'][target='_blank']", text: "https://guides.rubyonrails.org/action_controller_overview.html"
    assert_select "a[href='https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller'][target='_blank']", text: "https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller"
  end

  test "host review screen shows references for the current question" do
    game = games(:active_game)
    question = game.current_question
    question.references.create!(url: "https://guides.rubyonrails.org/action_controller_overview.html")

    sign_in_as(users(:alice))
    post finish_question_game_path(game)
    get game_path(game)

    assert_select "details", text: /References/
    assert_select "a[href='https://guides.rubyonrails.org/action_controller_overview.html'][target='_blank']", text: "https://guides.rubyonrails.org/action_controller_overview.html"
  end

  test "multiple players join and answer" do
    game = games(:active_game)
    question = game.current_question
    correct = question.answers.find_by(correct: true)
    wrong = question.answers.find_by(correct: false)

    alice = participants(:alice_in_game)
    bob = participants(:bob_in_game)

    Response.create!(
      participant: alice,
      question: question,
      answer: correct,
      responded_at: game.question_opened_at + 1.second
    )

    Response.create!(
      participant: bob,
      question: question,
      answer: wrong,
      responded_at: game.question_opened_at + 2.seconds
    )

    # Host sees 2/2 responses
    sign_in_as(users(:alice))
    get game_path(game)
    assert_select "[data-response-count]", text: /2\s*\/\s*2/
  end

  test "invalid game code shows 404" do
    get play_path(code: "XXXXXX")
    assert_response :not_found
  end

  test "player cannot answer after deadline" do
    game = games(:waiting_game)

    post play_path(code: game.code), params: { name: "LatePlayer" }

    sign_in_as(users(:alice))
    post start_game_path(game)
    game.reload
    question = game.current_question

    sign_out

    # Set question_opened_at far in the past
    game.update!(question_opened_at: 1.hour.ago)

    correct = question.answers.find_by(correct: true)
    assert_no_difference "Response.count" do
      post responses_path, params: {
        game_code: game.code,
        question_id: question.id,
        answer_id: correct.id
      }
    end
  end
end
