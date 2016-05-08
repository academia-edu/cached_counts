require 'spec_helper'

describe 'caches_count_of' do
  let!(:university) { University.create! }
  let!(:confirmed_user_dept) { Department.create! university: university }
  let!(:unconfirmed_user_dept) { Department.create! university: university }
  let!(:confirmed_user) { User.create! confirmed: true, department: confirmed_user_dept }
  let!(:unconfirmed_user) { User.create! confirmed: false, department: unconfirmed_user_dept }
  let!(:following) { Following.create! follower: unconfirmed_user, followee: confirmed_user }

  it 'counts zero when no records match' do
    expect(unconfirmed_user.followers_count).to eq(0)
    expect(unconfirmed_user_dept.users_count).to eq(0)
  end

  it 'counts one when a record matches' do
    expect(confirmed_user.followers_count).to eq(1)
    expect(confirmed_user_dept.users_count).to eq(1)
    expect(university.users_count).to eq(1)
  end

  context 'on record update' do
    it 'increments directly associated count when record becomes matching' do
      expect {
        unconfirmed_user.update_attribute :confirmed, true
      }.to change {
        unconfirmed_user_dept.users_count
      }.by 1
    end

    it 'increments indirectly associated count when record becomes matching' do
      expect {
        unconfirmed_user.update_attribute :confirmed, true
      }.to change {
        university.users_count
      }.by 1
    end

    it 'decrements directly associated count when record becomes non-matching' do
      expect {
        confirmed_user.update_attribute :confirmed, false
      }.to change {
        confirmed_user_dept.users_count
      }.by -1
    end

    it 'decrements indirectly associated count when record becomes non-matching' do
      expect {
        confirmed_user.update_attribute :confirmed, false
      }.to change {
        university.users_count
      }.by -1
    end
  end

  context 'on record creation' do
    it 'increments count without condition' do
      added_user = User.create!
      expect {
        Following.create! follower: added_user, followee: confirmed_user
      }.to change {
        confirmed_user.followers_count
      }.by 1
    end

    it 'increments directly associated count when matching' do
      expect {
        User.create!(confirmed: true, department: confirmed_user_dept)
      }.to change {
        confirmed_user_dept.users_count
      }.by 1
    end

    it 'increments indirectly associated count when matching' do
      expect {
        User.create!(confirmed: true, department: confirmed_user_dept)
      }.to change {
        university.users_count
      }.by 1
    end

    it 'does nothing to directly associated count when non-matching' do
      expect {
        User.create!(confirmed: false, department: confirmed_user_dept)
      }.not_to change {
        confirmed_user_dept.users_count
      }
    end

    it 'does nothing to indirectly associated count when non-matching' do
      expect {
        User.create!(confirmed: false, department: confirmed_user_dept)
      }.not_to change {
        university.users_count
      }
    end
  end

  context 'on record destruction' do
    it 'decrements count without condition' do
      expect {
        unconfirmed_user.destroy
      }.to change {
        confirmed_user.followers_count
      }.by -1
    end

    it 'decrements directly associated count when matching' do
      expect {
        confirmed_user.destroy
      }.to change {
        confirmed_user_dept.users_count
      }.by -1
    end

    it 'decrements indirectly associated count when matching' do
      expect {
        confirmed_user.destroy
      }.to change {
        university.users_count
      }.by -1
    end

    it 'does nothing to directly associated count when non-matching' do
      expect {
        unconfirmed_user.destroy
      }.not_to change {
        unconfirmed_user_dept.users_count
      }
    end

    it 'does nothing to indirectly associated count when non-matching' do
      expect {
        unconfirmed_user.destroy
      }.not_to change {
        university.users_count
      }
    end
  end

end

