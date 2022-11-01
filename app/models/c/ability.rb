# frozen_string_literal: true

module C
  class Ability
    include CanCan::Ability

    def initialize(_user)
      can :manage, :all
    end
  end
end
