class UserPolicy < ApplicationPolicy
  def show?
    user_is_owner?
  end

  def update?
    user_is_owner?
  end

  def destroy?
    user_is_owner?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(id: user.id)
    end

    private

    attr_reader :user, :scope
  end

  private

  def user_is_owner?
    user == record
  end
end
