# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tasks', type: :system do
  describe 'タスク機能' do
    let!(:label) { create(:label, name: 'System Spec') }
    let!(:priority) { create(:priority, name: '中', priority: 50) }
    let!(:status) { create(:status, name: '着手') }
    let!(:user) { create(:user, id: 1, name: '太郎') }

    context 'タスク一覧' do
      let!(:first_task) { create(:task, user_id: user.id, priority_id: priority.id, time_limit: '2021-01-08T00:00', created_at: '2021-01-01T00:00') }
      let!(:second_task) { create(:task, user_id: user.id, priority_id: low_priority.id, time_limit: '2021-04-08T00:00', created_at: '2021-02-01T00:00') }
      let!(:third_task) { create(:task, user_id: user.id, priority_id: high_priority.id, time_limit: '2021-03-08T00:00', created_at: '2021-03-01T00:00') }
      let(:low_priority) { create(:priority, name: '低', priority: 1) }
      let(:high_priority) { create(:priority, name: '高', priority: 100) }
      let(:priority_tds) { page.all('.priorities') }
      let(:time_limit_tds) { page.all('.time-limits') }
      let(:created_at_tds) { page.all('.created-date') }

      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
      end

      it '作成日時の降順で並んでいる' do
        expect(created_at_tds[2]).to have_content first_task.created_at
        expect(created_at_tds[1]).to have_content second_task.created_at
        expect(created_at_tds[0]).to have_content third_task.created_at
      end

      it '優先度を奇数回押下すると昇順で並ぶ' do
        click_link '優先度'
        expect(priority_tds[0]).to have_content second_task.priority.name
        expect(priority_tds[1]).to have_content first_task.priority.name
        expect(priority_tds[2]).to have_content third_task.priority.name
      end

      it '優先度を偶数回押下すると降順で並ぶ' do
        click_link '優先度'
        click_link '優先度'
        expect(priority_tds[2]).to have_content second_task.priority.name
        expect(priority_tds[1]).to have_content first_task.priority.name
        expect(priority_tds[0]).to have_content third_task.priority.name
      end

      it '終了日時を奇数回押下すると昇順で並ぶ' do
        click_link '終了期限'
        expect(time_limit_tds[0]).to have_content first_task.time_limit
        expect(time_limit_tds[1]).to have_content third_task.time_limit
        expect(time_limit_tds[2]).to have_content second_task.time_limit
      end

      it '終了日時を偶数回押下すると降順で並ぶ' do
        click_link '終了期限'
        click_link '終了期限'
        expect(time_limit_tds[2]).to have_content first_task.time_limit
        expect(time_limit_tds[1]).to have_content third_task.time_limit
        expect(time_limit_tds[0]).to have_content second_task.time_limit
      end
    end

    context 'タスク詳細' do
      let!(:task) { create(:task, user_id: user.id) }

      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
        click_link '詳細', href: task_path(task)
      end

      it 'タスクの情報が正しく画面に表示されている' do
        expect(page).to have_content task.name
        expect(page).to have_content task.label.name
        expect(page).to have_content task.priority.name
        expect(page).to have_content task.status.name
        expect(page).to have_content task.time_limit
        expect(page).to have_content task.description
      end
    end

    context 'タスク作成' do
      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
        click_link '+ タスク作成', href: new_task_path
        fill_in('task_name', with: '作業タスクA')
        select(label.name, from: 'task_label_id')
        select(priority.name, from: 'task_priority_id')
        select(status.name, from: 'task_status_id')
        fill_in('task_time_limit', with: '2021-01-01T00:00')
        fill_in('task_description', with: "Aという作業.\nテストです.")
      end

      it 'ボタンを押下したら作成に成功し、一覧画面へ遷移する' do
        click_button '作成'
        expect(page).to have_current_path tasks_path, ignore_query: true
        expect(page).to have_content '作業タスクA'
      end

      it '"タスクを入力してください" と画面に表示され、作成に失敗する' do
        fill_in('task_name', with: '')

        click_button '作成'
        expect(page).to have_content 'タスクを入力してください'
      end

      it '"優先度を選択してください" と画面に表示され、作成に失敗する' do
        select('優先度を選択', from: 'task_priority_id')

        click_button '作成'
        expect(page).to have_content '優先度を選択してください'
      end

      it '"ステータスを選択してください" と画面に表示され、作成に失敗する' do
        select('ステータスを選択', from: 'task_status_id')

        click_button '作成'
        expect(page).to have_content 'ステータスを選択してください'
      end
    end

    context 'タスク編集' do
      let!(:task) { create(:task, user_id: user.id) }

      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
        click_link '編集', href: edit_task_path(task)
      end

      it 'タスクの情報が正しく入力欄に表示されている' do
        expect(page).to have_field('task_name', with: task.name)
        expect(page).to have_select('task_label_id', selected: task.label.name)
        expect(page).to have_select('task_priority_id', selected: task.priority.name)
        expect(page).to have_select('task_status_id', selected: task.status.name)
        expect(page).to have_field('task_time_limit', with: task.time_limit.strftime('%Y-%m-%dT%H:%M:%S'))
        expect(page).to have_field('task_description', with: task.description)
      end

      it 'ボタンを押下したら更新に成功し、一覧画面へ遷移する' do
        fill_in('task_name', with: '作業タスクA')

        click_button '更新'
        expect(page).to have_current_path tasks_path, ignore_query: true
        expect(page).to have_content '作業タスクA'
      end

      it '"タスクを入力してください" と画面に表示され、更新に失敗する' do
        fill_in('task_name', with: '')

        click_button '更新'
        expect(page).to have_content 'タスクを入力してください'
      end
    end

    context 'タスク削除', js: true do
      let!(:task) { create(:task, user_id: user.id) }

      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
        click_link '削除', href: task_path(task)
      end

      it '削除確認ダイアログでキャンセルを押下したら、タスクが削除されない' do
        expect(page.dismiss_confirm).to eq '本当に削除しますか？'
        expect(page).to have_content task.name
      end

      it '削除確認ダイアログで OK を押下したら、タスクが削除される' do
        expect(page.accept_confirm).to eq '本当に削除しますか？'
        expect(page).to have_content 'タスクを削除しました'
        expect(page).not_to have_content task.name
      end
    end

    context 'タスク検索' do
      let!(:abc_task) { create(:task, name: 'abcタスク', status_id: completed.id, user_id: user.id, priority_id: priority.id) }
      let!(:xyz_task) { create(:task, name: 'xyzタスク', status_id: unstarted.id, user_id: user.id, priority_id: priority.id) }
      let!(:other_task) { create(:task, name: 'other', status_id: completed.id, user_id: user.id, priority_id: priority.id) }
      let(:unstarted) { create(:status, name: '未着手') }
      let(:completed) { create(:status, name: '完了') }

      before do
        visit login_path
        fill_in('name', with: user.name)
        fill_in('password', with: user.password)
        click_button 'ログイン'
      end

      it "'abc' で検索したら 'abcタスク' が表示される" do
        fill_in('search', with: 'abc')
        click_button '検索'
        expect(page).to have_content abc_task.name
        expect(page).not_to have_content xyz_task.name
        expect(page).not_to have_content other_task.name
      end

      it "'未' で検索したら 'xyzタスク' が表示される" do
        fill_in('search', with: '未')
        click_button '検索'
        expect(page).to have_content xyz_task.name
        expect(page).not_to have_content abc_task.name
        expect(page).not_to have_content other_task.name
      end

      it "'タスク' で検索したら 'abcタスク・xyzタスク' が表示される" do
        fill_in('search', with: 'タスク')
        click_button '検索'
        expect(page).to have_content abc_task.name
        expect(page).to have_content xyz_task.name
        expect(page).not_to have_content other_task.name
      end

      it "'完了' で検索したら 'abcタスク・otherタスク' が表示される" do
        fill_in('search', with: '完了')
        click_button '検索'
        expect(page).to have_content abc_task.name
        expect(page).to have_content other_task.name
        expect(page).not_to have_content xyz_task.name
      end

      it "'abcd' で検索したら 表示されない" do
        fill_in('search', with: 'abcd')
        click_button '検索'
        expect(page).not_to have_content abc_task.name
        expect(page).not_to have_content xyz_task.name
        expect(page).not_to have_content other_task.name
      end

      it "'' で検索したら 全て表示される" do
        fill_in('search', with: '')
        click_button '検索'
        expect(page).to have_content abc_task.name
        expect(page).to have_content xyz_task.name
        expect(page).to have_content other_task.name
      end
    end
  end
end
