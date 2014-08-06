require 'nokogiri'
require 'open-uri'
require 'pony'
require 'baby_erubis'

require 'pry'
require 'awesome_print'

module Asame
  VERSION = '0.0.1'

  def self.run
    Pony.options = {
      charset: 'UTF-8',
      via: :smtp,
      via_options: {
        address:              ENV['SMTPD_ADDRESS'],
        port:                 ENV['SMTPD_PORT'],
        user_name:            ENV['SMTPD_USERNAME'],
        password:             ENV['SMTPD_PASSWORD'],
        domain:               ENV['SMTPD_DOMAIN'],
        authentication:       :plain,
        enable_starttls_auto: true
      }
    }

    source = Source.new
    template = BabyErubis::Text.new.from_file("#{__dir__}/template.txt.erb")

    Pony.mail(
      subject: '名言と愚行に関するウィキ デイリー ランダム項目',
      to: ENV['MAIL_RECIPIENT'],
      body: template.render(source.to_h)
    )
  end

  class Source
    URL = 'http://totutohoku.b23.coreserver.jp/totutohoku/index.php?plugin=ifrandom'

    def initialize(url = URL)
      html = open(url).read.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
      @doc = Nokogiri::HTML(html)
    end

    def to_h
      {
        title: title,
        url: url,
        author: author,
        content: content,
        updated: updated,
        comments: comments
      }
    end

    def title
      @doc.css('#header h1.title a').text
    end

    def url
      @doc.css('#header > a').attr('href').value
    end

    def content
      @doc.css('.body > p').text
    end

    def author
      @doc.css('#content_1_0').children.first.text.chop.strip
    end

    def updated
      @doc.css('#lastmodified')
        .text
        .match(/(\d{4}-\d{2}-\d{2}\s.{3}\s\d{2}:\d{2}:\d{2})/)
        .to_s
    end

    def comments
      @doc.css('ul.list1 li').map do |li|
        strong = li.css('strong').remove
        comment_date = li.css('.comment_date').remove

        {
          name: strong.text,
          commented_at: comment_date.text,
          content: li.text.chop.strip
        }
      end
    end
  end
end

__END__
