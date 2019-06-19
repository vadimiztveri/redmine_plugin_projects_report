get 'projects_reports', to: redirect('projects_reports/quickly_decide')

get 'projects_reports/all_know', :to => 'projects_reports#all_know'
get 'projects_reports/quickly_decide', :to => 'projects_reports#quickly_decide'
get 'projects_reports/not_allow', :to => 'projects_reports#not_allow'
