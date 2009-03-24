module XssKiller
  module ActiveRecordExtension
    module ClassMethods
      def kills_xss(options = {})
        options[:allow_injection] ||= []
        options[:allow_injection].map!(&:to_s)
        options[:sanitize] ||= []
        options[:sanitize].map!(&:to_s)
        options[:allow_tidy] = true if options[:allow_tidy].nil?
        write_inheritable_attribute :xss_killer_options, options
        write_inheritable_attribute :kill_xss, true
      end
      
      def kill_xss?
        read_inheritable_attribute :kill_xss
      end

      def xss_killer_options
        read_inheritable_attribute :xss_killer_options
      end
    end

    def kill_xss(column_name, value)
      return value unless value.is_a?(String)
      return value unless self.class.kill_xss?
      return value unless XssKiller.rendering_html?
      if self.class.xss_killer_options[:allow_injection].include?(column_name.to_s)
        value
      elsif self.class.xss_killer_options[:sanitize].include?(column_name.to_s)
        sanitized = XssKiller.template.sanitize value
        formatted = XssKiller.template.simple_format sanitized
        if tidy_defined? && self.class.xss_killer_options[:allow_tidy]
            Tidy.open(:show_body_only => true, :char_encoding => "utf8", :output_xhtml => true) { |tidy| formatted = tidy.clean(formatted)}
        end
        formatted
      else
        ERB::Util.html_escape value
      end
    end
    
    def tidy_defined?
      defined?(Tidy) != nil
    end
  end
end
