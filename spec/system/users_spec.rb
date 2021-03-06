# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users', type: :system do
  let!(:task) { create(:task, priority: priority, status: status, user: user) }
  let!(:user) { create(:admin, name: 'Taro') }

  let(:priority) { create(:priority, name: 'low', priority: 1) }
  let(:status) { create(:status, name: 'unstarted') }

  context 'ユーザ一覧' do
    before do
      visit login_path
      fill_in('name', with: user.name)
      fill_in('password', with: user.password)
      click_button 'ログイン'
      click_link 'ユーザ一覧へ →'
    end

    it 'ユーザ名とタスク数が表示されていること' do
      expect(page).to have_selector '.user_names', text: user.name
      expect(page).to have_selector '#0', text: user.tasks.size
    end
  end

  context 'ユーザ登録' do
    before do
      visit login_path
      fill_in('name', with: user.name)
      fill_in('password', with: user.password)
      click_button 'ログイン'
      click_link 'ユーザ一覧へ →'
      click_link '+ ユーザ登録'
      fill_in('user[name]', with: 'Hanako')
      fill_in('user[password]', with: 'password')
      fill_in('user[password_confirmation]', with: 'password')
    end

    it 'ユーザを登録したら、ユーザ一覧に登録したユーザが表示される' do
      click_button '作成'
      expect(page).to have_current_path users_path
      expect(page).to have_content 'Hanako'
    end

    it '"ユーザ名を入力してください" と画面に表示され、登録に失敗する' do
      fill_in('user[name]', with: '')
      click_button '作成'
      expect(page).to have_content 'ユーザ名を入力してください'
    end

    it '"パスワードを入力してください" と画面に表示され、登録に失敗する' do
      fill_in('user[password]', with: '')
      click_button '作成'
      expect(page).to have_content 'パスワードを入力してください'
    end

    it '"パスワードは8文字以上で入力してください" と画面に表示され、登録に失敗する' do
      fill_in('user[password]', with: 'passwd')
      click_button '作成'
      expect(page).to have_content 'パスワードは8文字以上で入力してください'
    end

    it '"パスワード確認とパスワードの入力が一致しません" と画面に表示され、登録に失敗する' do
      fill_in('user[password_confirmation]', with: '')
      click_button '作成'
      expect(page).to have_content 'パスワード確認とパスワードの入力が一致しません'
    end
  end

  context 'ユーザ編集' do
    let!(:other_admin_user) { create(:admin, name: 'Hanako') }
    let!(:general_user) { create(:user, name: 'Jiro') }

    before do
      visit login_path
      fill_in('name', with: user.name)
      fill_in('password', with: user.password)
      click_button 'ログイン'
    end

    it 'ユーザの情報が正しく入力欄に表示されている' do
      click_link 'ユーザ一覧へ →'
      click_link '編集', href: edit_user_path(user)
      expect(page).to have_field('user[name]', with: user.name)
    end

    it 'ユーザを更新したら、ユーザ一覧に更新したユーザが表示される' do
      click_link 'ユーザ一覧へ →'
      click_link '編集', href: edit_user_path(user)
      fill_in('user[name]', with: 'TaroYamada')

      click_button '更新'
      expect(page).to have_current_path users_path
      expect(page).to have_selector '.user_names', text: 'TaroYamada'
    end

    it '"ユーザ名を入力してください" と画面に表示され、更新に失敗する' do
      click_link 'ユーザ一覧へ →'
      click_link '編集', href: edit_user_path(user)
      fill_in('user[name]', with: '')
      click_button '更新'
      expect(page).to have_content 'ユーザ名を入力してください'
    end

    it '"パスワードは8文字以上で入力してください" と画面に表示され、更新に失敗する' do
      click_link 'ユーザ一覧へ →'
      click_link '編集', href: edit_user_path(user)
      fill_in('user[password]', with: 'passwd')
      click_button '更新'
      expect(page).to have_content 'パスワードは8文字以上で入力してください'
    end

    it '"パスワード確認とパスワードの入力が一致しません" と画面に表示され、更新に失敗する' do
      click_link 'ユーザ一覧へ →'
      click_link '編集', href: edit_user_path(user)
      fill_in('user[password]', with: 'password')
      fill_in('user[password_confirmation]', with: '')
      click_button '更新'
      expect(page).to have_content 'パスワード確認とパスワードの入力が一致しません'
    end

    it '一般ユーザを管理ユーザにすることができる' do
      click_link 'ユーザ一覧へ →'
      expect(page).to have_content '一般ユーザ', count: 1
      expect(page).to have_content '管理ユーザ', count: 2

      click_link '編集', href: edit_user_path(general_user)
      choose '管理ユーザ'
      click_button '更新'

      expect(page).to have_current_path users_path
      expect(page).not_to have_content '一般ユーザ'
      expect(page).to have_content '管理ユーザ', count: 3
    end

    it '管理ユーザが2人以上の時、管理ユーザを一般ユーザにすることができる' do
      click_link 'ユーザ一覧へ →'
      expect(page).to have_content '管理ユーザ', count: 2

      click_link '編集', href: edit_user_path(other_admin_user)
      choose '一般ユーザ'
      click_button '更新'

      expect(page).to have_current_path users_path
      expect(page).to have_content '管理ユーザ', count: 1
    end

    it '管理ユーザが1人の時は、管理ユーザを一般ユーザにすることはできない' do
      other_admin_user.destroy

      click_link 'ユーザ一覧へ →'
      expect(page).to have_content '管理ユーザ', count: 1

      click_link '編集', href: edit_user_path(user)
      choose '一般ユーザ'
      click_button '更新'
      expect(page).to have_content '管理ユーザが1人もいなくなると、管理ユーザを作成することができなくなるので、管理ユーザは1人以上残す必要があります'
      expect(page).to have_content 'ユーザの種類は変更できません'

      visit users_path
      expect(page).to have_content '管理ユーザ', count: 1
    end
  end

  context 'ユーザ削除', js: true do
    let!(:other_user) { create(:user, name: 'Hanako') }

    before do
      visit login_path
      fill_in('name', with: user.name)
      fill_in('password', with: user.password)
      click_button 'ログイン'
      click_link 'ユーザ一覧へ →'
      click_link '削除', href: user_path(other_user)
    end

    it '削除確認ダイアログでキャンセルを押下したら、ユーザが削除されない' do
      expect(page.dismiss_confirm).to eq '本当に削除しますか？'
      expect(page).to have_content other_user.name
    end

    it '削除確認ダイアログで OK を押下したら、ユーザが削除される' do
      expect(page.accept_confirm).to eq '本当に削除しますか？'
      expect(page).to have_content 'ユーザを削除しました'
      expect(page).not_to have_content other_user.name
    end

    it '"管理ユーザが1人もいなくなると、管理ユーザを作成することができなくなるので、管理ユーザは1人以上残す必要があります" と表示され、ユーザが削除されない' do
      expect(page.dismiss_confirm).to eq '本当に削除しますか？'

      click_link '削除', href: user_path(user)
      expect(page.accept_confirm).to eq '本当に削除しますか？'
      expect(page).to have_content '管理ユーザが1人もいなくなると、管理ユーザを作成することができなくなるので、管理ユーザは1人以上残す必要があります'
      expect(page).to have_content user.name
    end
  end

  context 'ユーザが作成したタスクの一覧' do
    let!(:other_user) { create(:user, name: 'Hanako') }
    let(:other_user_task) { create(:task, priority: priority, status: status, user: other_user) }

    before do
      visit login_path
      fill_in('name', with: user.name)
      fill_in('password', with: user.password)
      click_button 'ログイン'
      click_link 'ユーザ一覧へ →'
      click_link '作成したタスク一覧', href: user_path(user)
    end

    it 'タスク名等が表示されていること' do
      expect(page).to have_content task.name
      expect(page).to have_content task.label.name
      expect(page).to have_content task.priority.name
      expect(page).to have_content task.status.name
      expect(page).to have_content task.time_limit
      expect(page).to have_content task.created_at

      expect(page).not_to have_content other_user_task.name
    end
  end

  context '一般ユーザ' do
    let!(:other_user) { create(:user, name: 'Hanako') }

    before do
      visit login_path
      fill_in('name', with: other_user.name)
      fill_in('password', with: other_user.password)
      click_button 'ログイン'
      click_link 'ユーザ一覧へ →'
    end

    it 'アクセスした際に、エラーページを表示すること' do
      expect(page).to have_content '403 Forbidden'
    end
  end
end
