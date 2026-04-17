require "pathname"
require "yaml"

namespace :quiz do
  task :import, [ :path ] => :environment do |_task, args|
    provided_path = args[:path].to_s.strip
    raise ArgumentError, "Usage: bin/rails quiz:import[path/to/file.yml]" if provided_path.blank?

    file_path = Pathname.new(provided_path)
    file_path = Rails.root.join(provided_path) unless file_path.absolute?
    raise ArgumentError, "Quiz file not found: #{file_path}" unless file_path.exist?

    payload = YAML.safe_load(file_path.read)
    raise ArgumentError, "Quiz file must contain a top-level array of questions" unless payload.is_a?(Array)

    quiz_title = file_path.basename(file_path.extname.to_s).to_s.tr("_-", " ").titleize
    imported_quiz = nil

    Quiz.transaction do
      imported_quiz = Quiz.find_or_create_by!(title: quiz_title)
      fail ArgumentError, "Quiz with title '#{quiz_title}' has games! Remove games or rename the quiz before importing." if imported_quiz.games.any?

      imported_quiz.questions.destroy_all

      payload.each_with_index do |raw_entry, question_index|
        entry = raw_entry.is_a?(Hash) ? raw_entry.stringify_keys : nil
        raise ArgumentError, "Question ##{question_index + 1} must be a mapping" unless entry

        body = entry["question"].to_s
        raise ArgumentError, "Question ##{question_index + 1} is missing question text" if body.strip.blank?

        answers = entry["answers"]
        raise ArgumentError, "Question ##{question_index + 1} must have at least one answer" unless answers.is_a?(Array) && answers.any?

        correct_index = entry["correct"]
        raise ArgumentError, "Question ##{question_index + 1} has an invalid correct answer index" unless correct_index.is_a?(Integer) && correct_index.between?(0, answers.length - 1)

        time_limit_seconds = entry["time_limit_seconds"].presence || 15

        question = imported_quiz.questions.create!(
          body: body,
          position: question_index + 1,
          time_limit_seconds: time_limit_seconds
        )

        references = entry["references"]
        raise ArgumentError, "Question ##{question_index + 1} references must be an array" if references.present? && !references.is_a?(Array)

        Array(references).each do |reference_url|
          reference_text = reference_url.to_s.strip
          raise ArgumentError, "Question ##{question_index + 1} has a blank reference" if reference_text.blank?

          question.references.create!(url: reference_text)
        end

        answers.each_with_index do |answer_body, answer_index|
          answer_text = answer_body.to_s.strip
          raise ArgumentError, "Question ##{question_index + 1} has a blank answer" if answer_text.blank?

          question.answers.create!(
            body: answer_text,
            correct: answer_index == correct_index
          )
        end
      end
    end

    puts "Imported quiz '#{imported_quiz.title}' with #{imported_quiz.questions.count} questions"
  end
end
