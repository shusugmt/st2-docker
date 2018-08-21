st2components = %w[
  api
  api.gunicorn
  auth
  auth.gunicorn
  garbagecollector
  notifier
  resultstracker
  rulesengine
  sensorcontainer
  stream
  stream.gunicorn
  timersengine
  workflowengine
]

st2components.each do |component|
  source {
    type :tail
    path "/mnt/log/st2/#{component}.log"
    pos_file "/tmp/st2.#{component}.fluentd_pos_file"
    tag "st2.#{component}"
    parse {
      type :json
      time_key :timestamp_f
      keep_time_key true
    }
  }
end

source {
  type :tail
  path "/mnt/log/st2/actionrunner.*.log"
  pos_file "/tmp/st2.actionrunner.fluentd_pos_file"
  tag "st2.actionrunner"
  parse {
    type :json
    time_key :timestamp_f
    keep_time_key true
  }
}

match('st2.**') {
  type :copy
  store {
    type :forward
    server {
      host ENV.fetch('FLUENTD_REMOTE_HOST')
    }
    buffer {
      flush_mode :immediate
    }
  }
  if ENV['FLUENTD_LOG_STDOUT']
    store {
      type :stdout
    }
  end
}
