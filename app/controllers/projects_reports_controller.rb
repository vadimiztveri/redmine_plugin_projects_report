class ProjectsReportsController < ApplicationController
  before_filter :check_enabled_plugin
  before_filter :projects_with_filtres

  def all_know
    base_event_id = Setting.plugin_projects_reports[:events_all_know_id]
    tracker_id = Setting.plugin_projects_reports[:trecker_all_know_id]
    get_data(base_event_id, tracker_id, true)
  end

  def quickly_decide
    base_event_id = Setting.plugin_projects_reports[:events_quickly_decide_id]
    tracker_id = Setting.plugin_projects_reports[:trecker_quickly_decide_id]
    get_data(base_event_id, tracker_id)
  end

  def not_allow
    base_event_id = Setting.plugin_projects_reports[:events_not_allow_id]
    tracker_id = Setting.plugin_projects_reports[:trecker_not_allow_id]
    get_data(base_event_id, tracker_id)
  end

  private

  def get_data(base_event_id, tracker_id, show_issues_without_version=false)
    @show_issues_without_version = show_issues_without_version

    @projects_with_counts = ProjectsWithCounts.new(base_event_id, tracker_id, @leader_id, @projects).run
    projects_and_percents = get_projects_and_percents
    @projects_sorting_by = GetProjectsSortingBy.new(projects_and_percents, @leader_id).run

    project_ids = projects_and_percents.map{ |key, value| key.to_i }
    @filter[:projects] = @filter[:projects].select{ |project| project_ids.include?(project[:id]) }

    leaders = @projects_sorting_by[:leaders].map{ |key, value| key }
    @filter[:leaders] = @filter[:leaders].select{ |leader| leaders.include?(leader[:name]) }

    @events ||= CustomField.find(base_event_id).enumerations.active.order(:position)
    @totals = get_totals
  end

  def check_enabled_plugin
    unless Setting.plugin_projects_reports[:enabled]
      render_404 and return
    end
  end

  def get_leaders(projects, leader_id)
    leaders_ids = projects
                    .map{ |project| project.custom_value_for(leader_id).value }
                    .uniq
                    .sort

    has_empty = leaders_ids.include?('')
    leaders_ids = leaders_ids - [''] if has_empty

    leaders = leaders_ids.map{ |id| CustomField.find(leader_id).enumerations.where(id: id).take }
    leaders = leaders.map{ |leader| { name: leader.name, id: leader.id } }

    leaders << { name: t('projects_reports.no_leader'), id: '0' } if has_empty
    leaders
  end

  def projects_with_filtres
    parent_slug = Setting.plugin_projects_reports[:parent_slug]
    @project = Project.find_by(identifier: parent_slug)
    @projects = @project.children.visible.sorted
    @projects = @projects.reject{ |project| project.versions.open.empty? }

    @leader_id = Setting.plugin_projects_reports[:leader_id]
    @leaders = get_leaders(@projects, @leader_id)

    @filter = {}

    if params['project'].present? && params['project'].any?
      projects_ids = params['project'].first.keys.map{ |id| id.to_i }

      @filter[:projects] = @projects.map{ |project| {
                                                      name: project.name,
                                                      id: project.id,
                                                      checked: projects_ids.include?(project.id)
                                                    }}
      @filter[:projects_all] = false
      @projects = @projects.select{ |project| projects_ids.include?(project.id) }
    else
      projects_ids = @projects.map(&:id)
      @filter[:projects] = @projects.map{ |project| {
                                                      name: project.name,
                                                      id: project.id,
                                                      checked: true
                                                    }}
      @filter[:projects_all] = true
    end

    has_no_leader_projects = @leaders.map{ |leader| leader[:id] }.include?('0')

    if params['leader'].present? && params['leader'].any?
      leaders_ids = params['leader'].first.keys.map{ |id| id.to_i }

      @filter[:leaders] = @leaders.map{ |leader| {
                                                    name: leader[:name],
                                                    id: leader[:id],
                                                    checked: leaders_ids.include?(leader[:id])
                                                  }}
      if has_no_leader_projects
        @filter[:leaders].reject!{ |leader| leader[:id] == '0' }
        @filter[:leaders] << {
                                name: t('projects_reports.no_leader'),
                                id: 0,
                                checked: leaders_ids.include?(0)
                              }
      end

      @filter[:leaders_all] = false
      @projects = @projects.select{ |project| leaders_ids.include?(project.custom_value_for(14).value.to_i) }
    else
      leaders_ids = @leaders.map{ |leader| leader[:id].to_i }
      @filter[:leaders] = @leaders.map{ |leader| {
                                                    name: leader[:name],
                                                    id: leader[:id],
                                                    checked: true
                                                  }}
      if has_no_leader_projects
        @filter[:leaders].reject!{ |leader| leader[:id] == '0' }
        @filter[:leaders] << {
                                name: t('projects_reports.no_leader'),
                                id: 0,
                                checked: true
                              }
      end

      @filter[:leaders_all] = true
    end
  end

  def get_projects_and_percents
    projects_and_percents = {}

    @projects_with_counts.each do |project_id, project|
      projects_and_percents[project_id] = {
        percent: project[:versions_header][:percent],
        versions_count: project[:versions_count],
        issues_count: project[:issues_count]
      }
    end

    projects_and_percents
  end

  def get_totals
    @projects_with_counts

    events_data = @projects_with_counts.map{ |project_id, value| value[:versions_header][:events] }

    totals = {}

    @events.map(&:id).each do |id|
      closed_versions_sum = events_data.map{ |event_data| event_data[id][:closed_versions_size] }.sum
      versions_sum = events_data.map{ |event_data| event_data[id][:versions_size] }.sum
      # mast_opened_versions_sum = events_data.map{ |event_data| event_data[id][:mast_opened_versions_size] }.sum

      totals[id] = {
        closed_versions_sum: closed_versions_sum,
        versions_sum: versions_sum
      }
    end

    total_closed_versions_sum = totals.map{ |key, total| total[:closed_versions_sum] }.sum
    total_versions_sum = totals.map{ |key, total| total[:versions_sum] }.sum
    average_percent = get_average_percent(total_versions_sum, total_closed_versions_sum)

    {
      total_percent: average_percent,
      total_color: get_color(average_percent),
      total_versions: totals
    }

  end

  def get_average_percent(total_versions_sum, total_closed_versions_sum)
    if total_versions_sum == 0
      nil
    else
      ((total_closed_versions_sum.to_f / total_versions_sum.to_f) * 100).to_i
    end
  end

  def get_color(average_percent)
    if average_percent.nil?
      'white'
    elsif average_percent > 80
      'green'
    elsif average_percent > 50
      'yellow'
    else
      'red'
    end
  end
end
