class Api::V1::BicyclePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_owns_bicycle?
  end

  def create?
    true
  end

  def update?
    user_owns_bicycle?
  end

  def destroy?
    user_owns_bicycle?
  end

  def record_ride?
    user_owns_bicycle?
  end

  def record_maintenance?
    user_owns_bicycle?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(user: user)
    end

    private

    attr_reader :user, :scope
  end

  private

  def user_owns_bicycle?
    record.user_id == user.id
  end
end
