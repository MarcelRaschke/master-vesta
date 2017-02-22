# frozen_string_literal: true
# Controller for user enrollments (bulk-adding)
class EnrollmentsController < ApplicationController
  def new
    @enrollment = Enrollment.new
  end

  def create
    result = Enrollment.enroll(enrollment_params)
    @enrollment = result[:enrollment]
    handle_action(**result)
  end

  private

  def authorize!
    authorize Enrollment
  end

  def enrollment_params
    params.require(:enrollment).permit(:ids).to_h.transform_keys(&:to_sym)
          .merge(querier: querier)
  end

  def querier
    return nil unless env?('QUERIER')
    # we can't use the `env` helper because Rails implements a deprecated env
    # method in controllers
    ENV['QUERIER'].constantize
  end
end