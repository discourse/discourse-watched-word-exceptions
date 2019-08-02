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
        @amended_actions ||= super.tap do | enum |
          enum.update(exceptions: 99)
        end
      end
    end

    WatchedWord.singleton_class.prepend WatchedWordExtension

    module WordWatcherExtension
      def word_matcher_regexp(action, *args)
        return super unless SiteSetting.watched_word_exceptions_enabled
        existing_regex = super
        return existing_regex if action.to_sym == :exceptions || existing_regex.nil?

        exception_regex = self.word_matcher_regexp(:exceptions)
        return existing_regex if exception_regex.nil?

        new_regex_string = "(?!#{exception_regex.source})(?:#{existing_regex.source})"
        return Regexp.new(new_regex_string, Regexp::IGNORECASE)
      end
    end

    WordWatcher.singleton_class.prepend WordWatcherExtension

  end

end
