desc "Updates the definition index in Algolia"

namespace :algolia do
  task :update_index => :environment do
    puts "Updating index in Algolia..."
    index = Algolia::Index.new('flowtyped_definitions')

    response = HTTParty.get('https://api.github.com/repos/flowtype/flow-typed/git/trees/master:definitions/npm?recursive=1')
    body = JSON.parse(response.body)

    batch = body['tree'].map do |path|
      flow = path['path'].scan(/\/(flow_.+)/).flatten.first
      definition = path['path'].scan(/(.+v\d.+)\/flow/).flatten.first

      next { type: nil } unless flow && definition

      split = definition.split('_v')

      {
        definition: split[0],
        version: split[1],
        flow: flow,
        type: path['type'],
      }
    end.select do |typedef|
      typedef[:type] == "tree"
    end.group_by do |typedef|
      typedef[:definition]
    end.map do |typedef|
      {
        definition: typedef[0],
        versions: typedef[1],
        objectID: typedef[0]
      }
    end

    index.add_objects(batch)
  end
end
