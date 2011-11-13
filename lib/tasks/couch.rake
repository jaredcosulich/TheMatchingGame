namespace :couch do
  task :create_views => :environment do
    LOG_DB.save_doc({
        "_id" => "_design/date_player",
        "views" => {
            "views" => {
                "map" => "function(doc) {\n  emit([doc.time.split(\" \")[0],doc.player.player.id], 1);\n}",
                "reduce" => "function (key, values, rereduce) {\n    return sum(values);\n}\n"
            }
        }
    })
    LOG_DB.save_doc({
        "_id" => "_design/player",
        "views" =>
            {"path" =>
                {"map" => "function(doc) {\n  if (doc.player) emit([doc.player.player.id, doc.time], doc.request.path);\n}"}
            }
    })
  end

  task :drop_views => :environment do
    ["_design/player", "_design/date_player"].each do |doc_name|
      LOG_DB.delete_doc(LOG_DB.get(doc_name)) rescue nil
    end
  end
end
