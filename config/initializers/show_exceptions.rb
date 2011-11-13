module ActionDispatch
  class ShowExceptions
    private
      def render_exception_with_template(env, exception)
        if exception.kind_of?(ActionController::RoutingError)
          body = ApplicationController.action("not_found").call(env)
          log_error(exception)
          body
        else
          render_exception_without_template(env, exception)
        end

      rescue
        render_exception_without_template(env, exception)
      end

      alias_method_chain :render_exception, :template
  end
end
