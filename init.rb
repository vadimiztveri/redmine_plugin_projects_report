require 'redmine'

Redmine::Plugin.register :projects_reports do
  name 'Projects Reports plugin'
  author 'Vadim Galkin (GalkinVI@mosreg.ru)'
  description 'Отчет по проектам с цветовыми индикаторами стадии выполнения'
  version '0.0.3'

  settings default: {
            enabled: false,
            parent_slug: 'centr_upravleniya_regionom',
            leader_id: '14',

            events_all_know_id: '20',
            trecker_all_know_id: '5',

            events_quickly_decide_id: '21',
            trecker_quickly_decide_id: '7',

            events_not_allow_id: '16',
            trecker_not_allow_id: '1',

            status_new_id: '1',
            status_complete_id: '3',
            status_in_work_id: '2',
            status_returned_id: '6',
            status_closed_id: '5'
          },
          partial: 'settings/projects_reports'

end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push 'Отчеты',
            '/projects_reports',
            {
              caption: :label_projects_reports,
              if: proc { |project|
                    slug = Setting.plugin_projects_reports[:parent_slug]

                    Setting.plugin_projects_reports[:enabled] &&
                      (project&.identifier == slug || project&.parent&.identifier == slug)
                  }
            }
end
