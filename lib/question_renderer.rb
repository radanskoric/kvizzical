require "kramdown"
require "kramdown-parser-gfm"
require "rouge"
require "open3"
require "shellwords"

class QuestionRenderer
  def initialize(markdown, anchor_resolver: nil)
    @parsed_document = parse_document(markdown)
  end

  class CodeFormatter < ::Rouge::Formatter
    # @option opts [String] :css_class ('highlight')
    # @option opts [true/false] :line_numbers (false)
    #
    # Content will be wrapped in a tag (`div` if tableized, `pre` if
    # not) with the given `:css_class`.
    def initialize(opts = {})
      @formatter = Rouge::Formatters::HTML.new
      @formatter = Rouge::Formatters::HTMLTable.new(@formatter, opts) if opts[:line_numbers]
      @css_class = opts.fetch(:css_class, "highlight")
    end

    # @yield the html output.
    def stream(tokens, &b)
      yield %(<div class="max-w-full overflow-x-auto"><pre class="#{@css_class}"><code>)
      @formatter.stream(tokens, &b)
      yield "</code></pre></div>"
    end
  end

  class HtmlConverter < Kramdown::Converter::Html
    MAX_CODE_LINE_LENGTH = 82

    def convert_codeblock(el, indent)
      code_content = el.value.strip

      <<~HTML
        <div class="not-prose font-mono text-sm bg-slate-50 font-bold rounded-xl border border-gray-200 pb-2 pl-2 break-inside-avoid">
          <div class="text-xs sm:text-sm flex justify-between items-center text-gray-400 font-bold h-6 leading-6 px-2">
            <span class="flex-1 text-center">#{code_block_title(el)}</span>
          </div>
          #{super}
        </div>
      HTML
    end

    def code_block_title(el)
      language = el.options[:lang]

      return "Code" if language.blank?

      language.to_s.capitalize
    end
  end

  def html
    html_output, _warnings = HtmlConverter.convert(@parsed_document.root, @parsed_document.options)
    html_output
  end

  private

  def parse_document(markdown)
    Kramdown::Document.new(
      markdown,
      input: "GFM",
      hard_wrap: false,
      syntax_highlighter: "rouge",
      syntax_highlighter_opts: {
        formatter: CodeFormatter,
        wrap_long_lines: true,
        span: { line_numbers: false },
        block: {
          line_numbers: false
        }
      }
    )
  end
end
