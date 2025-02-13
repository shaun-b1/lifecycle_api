class ComponentPolicy < ApplicationPolicy
  def show?
    user_owns_component?
  end

  def create?
    record.bicycle&.user_id == user.id
  end

  def update?
    user_owns_component?
  end

  def destroy?
    user_owns_component?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.joins(:bicycle).where(bicycles: { user_id: user.id })
    end

    private

    attr_reader :user, :scope
  end

  private

  def user_owns_component?
    record.bicycle&.user_id == user.id
  end
end
