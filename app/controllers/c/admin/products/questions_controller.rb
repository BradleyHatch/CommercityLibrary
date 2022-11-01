# frozen_string_literal: true

require_dependency 'c/admin_controller'

module C
  module Admin
    module Products
      class QuestionsController < AdminController
        load_and_authorize_resource class: C::Product::Question, only: %i[index show destroy reply]

        def index
          @questions = @questions.ordered
        end

        def show
          @answers = @question.answers
          @answer = @question.answers.build
        end

        def destroy; end

        def reply
          @answer = @question.answers.build(answer_params)
          if @answer.save
            EbayJob.perform_now('send_answer', @answer)
            redirect_to @question
          else
            render :show
          end
        end

        private

        def answer_params
          params.require(:product_answer).permit(:body)
        end
      end
    end
  end
end
