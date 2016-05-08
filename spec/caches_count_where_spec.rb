require 'spec_helper'

describe 'caches_count_where' do
  let!(:user) { User.create!(confirmed: false) }

  it 'counts zero when no records match' do
    expect(User.confirmed_count).to eq(0)
  end

  it 'counts one when a record matches' do
    expect(User.unconfirmed_count).to eq(1)
  end

  context 'on record update' do
    it 'increments when record becomes matching' do
      expect {
        user.update_attribute :confirmed, true
      }.to change {
        User.confirmed_count
      }.by 1
    end

    it 'decrements when record becomes non-matching' do
      expect {
        user.update_attribute :confirmed, true
      }.to change {
        User.unconfirmed_count
      }.by -1
    end
  end

  context 'on record creation' do
    it 'increments when matching' do
      expect {
        User.create!(confirmed: true)
      }.to change {
        User.confirmed_count
      }.by 1
    end

    it 'does nothing when non-matching' do
      expect {
        User.create!(confirmed: true)
      }.not_to change {
        User.unconfirmed_count
      }
    end
  end

  context 'on record destruction' do
    it 'decrements when matching' do
      expect {
        user.destroy
      }.to change {
        User.unconfirmed_count
      }.by -1
    end

    it 'does nothing when non-matching' do
      expect {
        user.destroy
      }.not_to change {
        User.confirmed_count
      }
    end
  end

  it 'is accessible by alias' do
    expect(User.spammer_count).to eq(1)
  end

  it 'falls back to value saved on load when cache is empty' do
    allow(User.unconfirmed).to receive(:count) do
      # 2nd caller, while calculation is proceeding for first caller, should
      # get fallback value, rather than joining a thundering herd
      expect(User.unconfirmed_count).to eq(0)
      User.where(confirmed: [nil, false]).count
    end

    # 1st caller--should set the cache to the fallback value, then return
    # the true value
    expect(User.unconfirmed_count).to eq(1)

    # 3rd caller, after calculation has finished, should get true value
    expect(User.unconfirmed_count).to eq(1)
  end

end
