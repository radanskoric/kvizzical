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
    post start_game_path(game)
    assert_redirected_to game_path(game)
    game.reload
    assert game.active?
    assert_equal question1, game.current_question

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
    post finish_question_game_path(game)
    game.reload
    assert game.reviewing?

    post advance_game_path(game)
    assert_redirected_to game_path(game)
    game.reload
    assert game.active?
    assert_equal question2, game.current_question

    # Player sees new question
    get play_path(code: game.code)
    assert_select "[data-question-body]", text: question2.body

    # Finish and advance through remaining questions
    loop do
      game.reload
      break if game.finished?
      if game.active?
        post finish_question_game_path(game)
      elsif game.reviewing?
        post advance_game_path(game)
      end
    end
    assert game.finished?

    # Host sees game over
    get game_path(game)
    assert_select "[data-leaderboard]"

    # Player sees game over with leaderboard
    get play_path(code: game.code)
    assert_select "[data-game-status='finished']"
    assert_select "[data-leaderboard]"
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

    post start_game_path(game)
    game.reload
    question = game.current_question

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
