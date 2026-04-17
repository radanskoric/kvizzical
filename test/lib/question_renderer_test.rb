require "test_helper"
require "question_renderer"

class QuestionRendererTest < ActiveSupport::TestCase
  test "converts markdown content to HTML" do
    markdown_content = <<~MARKDOWN
      # Hello World

      This is a **bold** text and *italic* text.

      - Item 1
      - Item 2

      ```ruby
      def hello
        puts "Hello, World!"
      end
      ```
    MARKDOWN

    result = convert(markdown_content)

    expected_html = <<~HTML
      <h1 id="hello-world">Hello World</h1>

      <p>This is a <strong>bold</strong> text and <em>italic</em> text.</p>

      <ul>
        <li>Item 1</li>
        <li>Item 2</li>
      </ul>

      <div class="not-prose font-mono text-sm bg-slate-50 font-bold rounded-xl border border-gray-200 pb-2 pl-2 break-inside-avoid">
        <div class="text-xs sm:text-sm flex justify-between items-center text-gray-400 font-bold h-6 leading-6 px-2">
          <span class="flex-1 text-center">Ruby</span>
        </div>
        <div class="language-ruby highlighter-rouge"><div class="max-w-full overflow-x-auto"><pre class="highlight"><code><span class="k">def</span> <span class="nf">hello</span>
        <span class="nb">puts</span> <span class="s2">"Hello, World!"</span>
      <span class="k">end</span>
      </code></pre></div></div>

      </div>
    HTML

    assert_equal expected_html.strip, result.strip
  end

  private

    def convert(...)
      QuestionRenderer.new(...).html
    end
end
