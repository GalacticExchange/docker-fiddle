class ApphubAcc

  def self.get_fiddle(hash)
    case hash[:type]
      when 'dockerfile'
        path = "http://apphub.galacticexchange.io/api/store_applications/get?github_user=#{hash[:github_user]
        }&url_path=#{hash[:url_path]}&fields[]=dockerfile"
        path << 's' if hash[:service_name]
        uri = URI.parse(URI.escape(path))
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)

        answer = http.request(request)
        return nil if answer.code.eql?('404')

        if hash[:service_name]
          tmp = JSON.parse(answer.body)['dockerfiles']
          tmp.each do |dockerfile|
            if dockerfile['service'].eql? hash[:service_name]
              puts dockerfile
              return Fiddle.new(:code => dockerfile['text'], :code_type => 'dockerfile')
            end
          end
        else
          tmp = JSON.parse(answer.body)['dockerfile']
          puts tmp
          return Fiddle.new(:code => tmp, :code_type => 'dockerfile')
        end
      when 'compose'
        path = "http://apphub.galacticexchange.io/api/store_applications/get?github_user=#{hash[:github_user]
        }&url_path=#{hash[:url_path]}&fields[]=compose_file"
        uri = URI.parse(URI.escape(path))
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)

        answer = http.request(request)
        return nil if answer.code.eql?('404')
        tmp = JSON.parse(answer.body)['compose_file']
        puts tmp
        return Fiddle.new(:code => tmp, :code_type => 'compose')
      else
        return nil
    end
  end
end

