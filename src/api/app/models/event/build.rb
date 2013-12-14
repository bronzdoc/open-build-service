class Event::Build < Event::Package
  self.description = 'Package has finished building'
  self.abstract_class = true
  payload_keys :repository, :arch, :release, :readytime, :srcmd5,
               :rev, :reason, :bcnt, :verifymd5, :hostarch, :starttime, :endtime, :workerid, :versrel
end

class Event::BuildSuccess < Event::Build
  self.raw_type = 'BUILD_SUCCESS'
  self.description = 'Package has succeeded building'
end

class Event::BuildFail < Event::Build
  include BuildLogSupport

  self.raw_type = 'BUILD_FAIL'
  self.description = 'Package has failed to build'
  receiver_roles :maintainer

  def subject
    "Build failure of #{payload['project']}/#{payload['package']} in #{payload['repository']}/#{payload['arch']}"
  end

  def faillog
    begin
      size = get_size_of_log(payload['project'], payload['package'], payload['repository'], payload['arch'])
      offset = size - 18 * 1024
      offset = 0 if offset < 0
      log = raw_log_chunk(payload['project'], payload['package'], payload['repository'], payload['arch'], offset, size)
      begin
        log.encode!(invalid: :replace, undef: :replace, cr_newline: true)
      rescue Encoding::UndefinedConversionError
        # encode is documented not to throw it if undef: is :replace, but at least we tried - and ruby 1.9.3 is buggy
      end
      log = log.lines
      if log.length > 20
        log = log.slice(-19, log.length)
      end
      log.join
    rescue ActiveXML::Transport::Error
      nil
    end
  end

  def expanded_payload
    payload.merge('faillog' => faillog)
  end

  def custom_headers
    h = super
    h['X-OBS-Package'] = "#{payload['project']}/#{payload['package']}"
    h['X-OBS-Repository'] = "#{payload['repository']}/#{payload['arch']}"
    h['X-OBS-Worker'] = payload['workerid']
    h['X-OBS-Rebuild-Reason'] = payload['reason']
    h
  end

end

class Event::BuildUnchanged < Event::Build
  # no raw_type as it should not go to plugins
  self.description = 'Package has succeeded building with unchanged result'
end
