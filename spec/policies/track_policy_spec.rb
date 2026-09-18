require "rails_helper"

RSpec.describe TrackPolicy do
  let(:genre) { create(:genre) }
  let(:track) { create(:track, genre: genre) }

  def entitled_member
    user = create(:user)
    subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
    create(:genre_entitlement, subscription: subscription, genre: genre)
    user
  end

  # The actor x action matrix from gems.md section 15A, for this resource.
  describe "#show?" do
    it "allows anyone for a published track" do
      expect(described_class.new(nil, track).show?).to be(true)
    end

    it "denies a visitor for a draft" do
      expect(described_class.new(nil, create(:track, :draft)).show?).to be(false)
      expect(described_class.new(create(:user), create(:track, :draft)).show?).to be(false)
    end

    it "allows an editor for a draft" do
      expect(described_class.new(create(:user, :editor), create(:track, :draft)).show?).to be(true)
    end
  end

  describe "#download?" do
    it "denies a signed-out visitor" do
      expect(described_class.new(nil, track).download?).to be(false)
    end

    it "denies a signed-in member with no subscription" do
      expect(described_class.new(create(:user), track).download?).to be(false)
    end

    it "denies a member whose subscription does not cover the genre" do
      other_genre = create(:genre)
      user = create(:user)
      subscription = create(:subscription, :active, user: user, plan: create(:plan, genre_limit: 1))
      create(:genre_entitlement, subscription: subscription, genre: other_genre)

      expect(described_class.new(user, track).download?).to be(false)
    end

    it "allows an entitled member" do
      expect(described_class.new(entitled_member, track).download?).to be(true)
    end

    it "denies an admin who is not entitled" do
      # Staff access to the catalogue is not a licence. An admin who wants to
      # download must subscribe like anyone else.
      expect(described_class.new(create(:user, :admin), track).download?).to be(false)
    end
  end

  describe "default deny" do
    it "denies actions it has not opened" do
      policy = described_class.new(create(:user, :admin), track)

      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end
end
