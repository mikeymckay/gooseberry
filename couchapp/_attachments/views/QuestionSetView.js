// Generated by CoffeeScript 1.8.0
var QuestionSetCollectionView, QuestionSetEdit, QuestionSetResults, QuestionSetView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

QuestionSetView = (function(_super) {
  __extends(QuestionSetView, _super);

  function QuestionSetView() {
    this.render = __bind(this.render, this);
    return QuestionSetView.__super__.constructor.apply(this, arguments);
  }

  QuestionSetView.prototype.el = '#content';

  QuestionSetView.prototype.fetchAndRender = function(name) {
    this.questionSet = new QuestionSet({
      _id: name
    });
    return this.questionSet.fetch({
      success: (function(_this) {
        return function() {
          return _this.render();
        };
      })(this)
    });
  };

  QuestionSetView.prototype.render = function() {
    var editor, json;
    this.$el.html("<a href='#question_set/" + (this.questionSet.name()) + "/edit'>Edit</a> <pre class='readonly' id='editor'></pre>");
    editor = ace.edit('editor');
    editor.setTheme('ace/theme/dawn');
    editor.setReadOnly(true);
    editor.getSession().setMode('ace/mode/json');
    json = this.questionSet.toJSON();
    return editor.setValue(JSON.stringify(json, null, 2));
  };

  return QuestionSetView;

})(Backbone.View);

QuestionSetEdit = (function(_super) {
  __extends(QuestionSetEdit, _super);

  function QuestionSetEdit() {
    this.save = __bind(this.save, this);
    this.render = __bind(this.render, this);
    return QuestionSetEdit.__super__.constructor.apply(this, arguments);
  }

  QuestionSetEdit.prototype.el = '#content';

  QuestionSetEdit.prototype.fetchAndRender = function(name) {
    this.questionSet = new QuestionSet({
      _id: name
    });
    return this.questionSet.fetch({
      success: (function(_this) {
        return function() {
          return _this.render();
        };
      })(this)
    });
  };

  QuestionSetEdit.prototype.render = function() {
    var json;
    this.$el.html("<button id='save' type='button'>Save</button> <pre id='editor'></pre>");
    this.editor = ace.edit('editor');
    this.editor.setTheme('ace/theme/twilight');
    this.editor.getSession().setMode('ace/mode/json');
    json = this.questionSet.toJSON();
    return this.editor.setValue(JSON.stringify(json, null, 2));
  };

  QuestionSetEdit.prototype.events = {
    "click button#save": "save"
  };

  QuestionSetEdit.prototype.save = function() {
    return Gooseberry.save({
      doc: JSON.parse(this.editor.getValue()),
      success: (function(_this) {
        return function() {
          return Gooseberry.router.navigate("question_set/" + (_this.questionSet.name()), {
            trigger: true
          });
        };
      })(this)
    });
  };

  return QuestionSetEdit;

})(Backbone.View);

QuestionSetResults = (function(_super) {
  __extends(QuestionSetResults, _super);

  function QuestionSetResults() {
    this.analyze = __bind(this.analyze, this);
    this.renderTableContents = __bind(this.renderTableContents, this);
    this.renderTableStructure = __bind(this.renderTableStructure, this);
    return QuestionSetResults.__super__.constructor.apply(this, arguments);
  }

  QuestionSetResults.prototype.el = '#content';

  QuestionSetResults.prototype.fetchAndRender = function(name) {
    this.$el.html("<h1>" + name + "</h1> <div id='stats'></div>");
    this.questionSet = new QuestionSet({
      _id: name
    });
    return this.questionSet.fetch({
      success: (function(_this) {
        return function() {
          _this.renderTableStructure();
          return _this.questionSet.fetchResults({
            success: function(results) {
              _this.renderTableContents(results);
              return _this.analyze();
            }
          });
        };
      })(this)
    });
  };

  QuestionSetResults.prototype.renderTableStructure = function() {
    return this.$el.append("<table id='results'> <thead> " + (_(this.questionSet.questionStringsWithNumberAndDate()).map(function(header) {
      return "<th>" + header + "</th>";
    }).join("")) + " </thead> <tbody> </tbody> </table>");
  };

  QuestionSetResults.prototype.renderTableContents = function(results) {
    this.$el.find("tbody").html(_(results).map((function(_this) {
      return function(result) {
        var _i, _ref, _results;
        return "<tr> <td><a href='#log/" + result["from"] + "/" + (_this.questionSet.name()) + "'>" + result["from"] + "</a></td> <td>" + result["updated_at"] + "</td> " + (_((function() {
          _results = [];
          for (var _i = 0, _ref = _this.questionSet.questionStrings().length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this)).map(function(index) {
          return "<td>" + (result[index] || "-") + "</td>";
        }).join("")) + " </tr>";
      };
    })(this)).join(""));
    return this.$el.find("table").dataTable({
      order: [[1, "desc"]],
      iDisplayLength: 25,
      dom: 'T<"clear">lfrtip',
      tableTools: {
        sSwfPath: "js-libraries/copy_csv_xls_pdf.swf"
      }
    });
  };

  QuestionSetResults.prototype.analyze = function() {
    return Gooseberry.view({
      name: "analysis_by_question_set",
      key: this.questionSet.name(),
      include_docs: false,
      success: (function(_this) {
        return function(results) {
          var completeResults, completionDurations, fastestCompletion, incompletePercentage, incompleteResults, meanTimeToComplete, medianTimeToComplete, mistakeCount, mistakePercentage, mistakes, requiredIndices, slowestCompletion, totalResults;
          completionDurations = [];
          incompleteResults = [];
          completeResults = 0;
          mistakes = [];
          requiredIndices = _this.questionSet.get("required_indices");
          if (requiredIndices != null) {
            requiredIndices = JSON.parse(requiredIndices);
          }
          _(_(results.rows).pluck("value")).each(function(result) {
            if (requiredIndices != null) {
              if (_(requiredIndices).difference(result.validIndices).length === 0) {
                completeResults += 1;
                if (result.updatedAt && result.firstResultTime) {
                  completionDurations.push(moment(result.updatedAt).diff(moment(result.firstResultTime), "seconds"));
                }
              } else {
                incompleteResults.push(result["from"]);
              }
            }
            if (!_(result.invalidResult).isEmpty()) {
              return mistakes.push(result.invalidResult);
            }
          });
          mistakeCount = 0;
          _(mistakes).each(function(mistake) {
            return _(mistake).each(function(value, index) {
              return mistakeCount += 1;
            });
          });
          if (requiredIndices) {
            totalResults = completeResults + incompleteResults.length;
            incompletePercentage = "" + (Math.floor(incompleteResults.length / totalResults * 100)) + " %";
            mistakePercentage = "" + (Math.floor(100 * mistakeCount / (totalResults * requiredIndices.length))) + " %";
          }
          if (completionDurations.length > 0) {
            fastestCompletion = moment.duration(_(completionDurations).min(), "seconds").humanize();
            slowestCompletion = moment.duration(_(completionDurations).max(), "seconds").humanize();
            medianTimeToComplete = moment.duration(math.median(completionDurations), "seconds").humanize();
            meanTimeToComplete = moment.duration(math.mean(completionDurations), "seconds").humanize();
          }
          return _this.$el.find("#stats").html("<ul> <li>Median Time To Complete: " + medianTimeToComplete + " (Fastest: " + fastestCompletion + " - Slowest: " + slowestCompletion + ") <!-- <li>Mean Time To Complete: " + meanTimeToComplete + " --> <li>Number of incomplete results: <button type='button' id='toggleIncompletes'>" + incompleteResults.length + "</button> (" + incompletePercentage + ") <a href='http://gooseberry.tangerinecentral.org/send_reminders/" + (_this.questionSet.name()) + "/240'>Send reminder SMS</a> <li>Total number of validation failures: <button id='toggleMistakes' type='button'>" + mistakeCount + "</button> (" + mistakePercentage + ") </ul> <div id='incompleteResultsDetails' style='display:none'> <h2>Incomplete Results</h2> <ul> " + (_(incompleteResults).map(function(number) {
            return "<li>" + number;
          }).join("")) + " </ul> </div> <div id='mistakeDetails' style='display:none'> <h2>Validation Failures</h2> <table> <thead> <td>Question</td> <td>Answer</td> </thead> <tbody> " + (_(mistakes).map(function(mistake) {
            return _(mistake).map(function(value, index) {
              return "<tr> <td>" + (_this.questionSet.questionStrings()[index]) + "</td> <td>" + (value || "") + "</td> </tr>";
            }).join("");
          }).join("")) + " </tbody> </table> </div>");
        };
      })(this)
    });
  };

  QuestionSetResults.prototype.toggleIncompletes = function() {
    return $("#incompleteResultsDetails").toggle();
  };

  QuestionSetResults.prototype.toggleMistakes = function() {
    return $("#mistakeDetails").toggle();
  };

  QuestionSetResults.prototype.events = {
    "click button#save": "save",
    "click button#toggleMistakes": "toggleMistakes",
    "click button#toggleIncompletes": "toggleIncompletes"
  };

  return QuestionSetResults;

})(Backbone.View);

QuestionSetCollectionView = (function(_super) {
  __extends(QuestionSetCollectionView, _super);

  function QuestionSetCollectionView() {
    this.render = __bind(this.render, this);
    this["delete"] = __bind(this["delete"], this);
    this.reallyDelete = __bind(this.reallyDelete, this);
    this.createCopy = __bind(this.createCopy, this);
    this.copy = __bind(this.copy, this);
    this.interact = __bind(this.interact, this);
    return QuestionSetCollectionView.__super__.constructor.apply(this, arguments);
  }

  QuestionSetCollectionView.prototype.el = '#content';

  QuestionSetCollectionView.prototype.events = {
    "click td.name": "openQuestionSet",
    "click td.number-of-results": "openResults",
    "click #toggleNew": "toggleNew",
    "click #create": "create",
    "click #delete": "delete",
    "click #reallyDelete": "reallyDelete",
    "click #cancel": "cancel",
    "click #copy": "copy",
    "click #createCopy": "createCopy",
    "click #interact": "interact"
  };

  QuestionSetCollectionView.prototype.interact = function(event) {
    var name, target;
    name = $(event.target).closest("tr").attr("data-name");
    console.log(document.location.hostname);
    target = document.location.hostname === "localhost" ? "http://localhost:9393/22340/incoming" : "http://gooseberry.tangerinecentral.org/22340/incoming";
    return Gooseberry.router.navigate("interact/" + name + "?target=" + target, {
      trigger: true
    });
  };

  QuestionSetCollectionView.prototype.cancel = function() {
    return $("deleteMessage").html("");
  };

  QuestionSetCollectionView.prototype.copy = function(event) {
    this.copySource = $(event.target).closest("tr").attr("data-name");
    return $("#copyForm").html("<input style='text-transform: uppercase' id='copyFormField' value='COPY OF " + this.copySource + "'></input><button id='createCopy'>Create</button>");
  };

  QuestionSetCollectionView.prototype.createCopy = function() {
    var questionSet;
    questionSet = new QuestionSet({
      _id: this.copySource
    });
    return questionSet.fetch({
      success: (function(_this) {
        return function() {
          questionSet.clone();
          questionSet.set("_id", $("#copyFormField").val().toUpperCase());
          questionSet.unset("_rev");
          return questionSet.save({
            success: function() {
              console.log("AAA");
              return _this.render();
            },
            error: function() {
              return console.log("RAA");
            }
          });
        };
      })(this)
    });
  };

  QuestionSetCollectionView.prototype.reallyDelete = function() {
    var questionSet;
    questionSet = new QuestionSet({
      _id: this.deleteTarget
    });
    return questionSet.fetch({
      success: (function(_this) {
        return function() {
          return questionSet.destroy({
            success: function() {
              return _this.render();
            }
          });
        };
      })(this)
    });
  };

  QuestionSetCollectionView.prototype["delete"] = function(event) {
    this.deleteTarget = $(event.target).closest("tr").attr("data-name");
    return $("#deleteMessage").html("Are you sure you want to delete " + this.deleteTarget + "? <button id='reallyDelete'>Yes</button><button id='cancelDelete'>Cancel</button>");
  };

  QuestionSetCollectionView.prototype.create = function() {
    var newName;
    newName = $("#newName").val().toUpperCase();
    if (newName) {
      return Gooseberry.router.navigate("question_set/" + newName + "/new", {
        trigger: true
      });
    }
  };

  QuestionSetCollectionView.prototype.toggleNew = function() {
    return $("#new").toggle();
  };

  QuestionSetCollectionView.prototype.openResults = function(event) {
    var name;
    name = $(event.target).closest("tr").attr("data-name");
    return Gooseberry.router.navigate("question_set/" + name + "/results", {
      trigger: true
    });
  };

  QuestionSetCollectionView.prototype.openQuestionSet = function(event) {
    var name;
    name = $(event.target).closest("tr").attr("data-name");
    return Gooseberry.router.navigate("question_set/" + name, {
      trigger: true
    });
  };

  QuestionSetCollectionView.prototype.render = function() {
    var questionSets;
    questionSets = new QuestionSetCollection();
    return questionSets.fetch({
      success: (function(_this) {
        return function() {
          _this.$el.html("<h1>Question Sets</h1> <button id='toggleNew'>New</button> <br/> <div style='display:none' id='new'> <br/> Name:  <input id='newName' style='text-transform: uppercase' type='text'></input> <button id='create'>Create</button> <br/> </div> <br/> <div id='deleteMessage'></div> <div id='copyForm'></div> <table> <thead> <th>Name</th><th>Number of results</th><th/><th/> </thead> <tbody> " + (questionSets.map(function(questionSet) {
            return "<tr data-name='" + (questionSet.name()) + "'> <td class='name clickable'>" + (questionSet.name()) + "</td> <td class='clickable number-of-results'></td> <td><small><button id='interact'>interact</button></small></td> <td><small><button id='delete'>x</button></small></td> <td><small><button id='copy'>copy</button></small></td> </tr>";
          }).join("")) + " </tbody> </table>");
          return questionSets.each(function(questionSet) {
            return questionSet.fetchResults({
              success: function(results) {
                return $("tr[data-name='" + (questionSet.name()) + "'] td.number-of-results").html(results.length);
              }
            });
          });
        };
      })(this)
    });
  };

  return QuestionSetCollectionView;

})(Backbone.View);

//# sourceMappingURL=QuestionSetView.js.map
