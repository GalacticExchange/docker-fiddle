class LinterController < ApplicationController

  def lint
    case params[:code_type]
      when 'dockerfile'
        result = Linter.lint_dockerfile(params[:code])
      when 'compose'
        result = Linter.lint_compose(params[:code])
    end

    render :json => result
  end

end
