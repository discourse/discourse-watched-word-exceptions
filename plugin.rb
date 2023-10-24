# frozen_string_literal: true

# name: discourse-watched-word-exceptions
# about: Add a new type of watched word, which is used as exceptions for the rest
# version: 1.0
# authors: David Taylor
# url: https://github.com/discourse/discourse-watched-word-exceptions

enabled_site_setting :watched_word_exceptions_enabled

after_initialize do
  reloadable_patch do
    module WatchedWordExtension
      def actions
        return super unless SiteSetting.watched_word_exceptions_enabled
        @amended_actions ||= super.tap { |enum| enum.update(exceptions: 99) }
      end
    end

    WatchedWord.singleton_class.prepend WatchedWordExtension

    module WordWatcherExtension
      def word_matcher_regexp_list(action, **kwargs)
        return super unless SiteSetting.watched_word_exceptions_enabled
        existing_regexes = super(action, **kwargs)
        return existing_regexes if action.to_sym == :exceptions || existing_regexes.empty?

        exception_regexes = self.word_matcher_regexp_list(:exceptions, **kwargs)
        return existing_regexes if !exception_regexes.present?

        exception_regex = exception_regexes.map(&:source).join("|")

        existing_regexes.map do |existing_regex|
          new_regex_string = "(?!#{exception_regex})(?:#{existing_regex.source})"
          Regexp.new(new_regex_string, existing_regex.options)
        end
      end
    end

    WordWatcher.singleton_class.prepend WordWatcherExtension
  end
end
