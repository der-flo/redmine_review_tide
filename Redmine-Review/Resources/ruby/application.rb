class Application
  def initialize(window, hostname, auth_token, uninteresting_projects)
    @window = window
    @hostname = hostname
    @auth_token = auth_token
    @uninteresting_projects = uninteresting_projects
    prepare_ticket_template
    fetch_and_show
    wire_events
  end

  private

  def prepare_ticket_template
    f = "#{Ti.Filesystem.getResourcesDirectory.nativePath}/ruby/ticket.haml"
    @ticket_template = Haml::Engine.new(File.read(f))
  end

  def fetch_and_show
    tickets = Ticket.fetch(@hostname, @auth_token, @uninteresting_projects)

    query('.content article').remove
    tickets.each do |ticket|
      output = @ticket_template.render(Object.new, :ticket => ticket)
      query('.content').append(output)
    end

    timestamp = "Von #{Time.now.localtime.strftime('%d.%m.%y, %k:%M')}"
    query('#timestamp').html(timestamp)
  end

  def all_checkboxes
    nodes = query("input[type=checkbox]").get()
    ret = []
    0.upto(nodes.length - 1) do |idx|
      node = nodes[idx]
      ret << node if node
    end
    ret
  end
  def all_active_checkboxes
    all_checkboxes.select(&:checked) # { |cb| cb.checked }
  end

  def start_browser_for_tickets ids
    args = ids.collect { |id| "http://#{@hostname}/issues/#{id}" }.join(' ')
    `open #{args}`
  end

  def query(str)
    @window.jQuery(str)
  end

  # EVENTS #####################################################################
  def wire_events
    query('#open_tickets').click(method(:on_open_tickets_click))
    @window.setInterval(method(:on_refresh_interval), 5 * 60 * 1_000)
  end
  def on_refresh_interval
    # Die Liste aktualisieren, wenn die checkboxen nicht abgehakt sind
    fetch_and_show if all_checkboxes.all?(&:checked)
  end
  def on_open_tickets_click
    ids = all_active_checkboxes.collect do |cb|
      cb.getAttribute('id').split('_')[1].to_i
    end
    last_time = all_active_checkboxes.collect do |cb|
      cb.getAttribute('data-lt').to_i
    end.max

    # TODO: + #note-123
    start_browser_for_tickets(ids) unless ids.empty?
    Ticket.confirm(last_time) if last_time > 0

    fetch_and_show
    false
  end
end
