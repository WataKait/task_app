# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  it 'pass' do
    expect(build(:task)).to be_valid
  end

  it 'fail no name' do
    task = build(:task, name: nil)
    task.valid?
    expect(task.errors[:name]).to include(I18n.t('errors.messages.blank'))
  end

  it 'fail name too long' do
    task = build(:task, name: SecureRandom.alphanumeric(256))
    task.valid?
    expect(task.errors[:name]).to include(I18n.t('errors.messages.too_long', count: 255))
  end
end
