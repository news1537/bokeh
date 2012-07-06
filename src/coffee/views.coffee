# module setup stuff
if this.Continuum
  Continuum = this.Continuum
else
  Continuum = {}
  this.Continuum = Continuum

class DataTableView extends ContinuumView
  initialize : (options) ->
    super(options)
    @render()
    safebind(this, @model, 'change', @render)

  el: 'div'

  className: 'table table-striped table-bordered table-condensed' 

  render : () ->
    table_template = """
		<table class='table table-striped table-bordered table-condensed' id='{{ tableid }}'></table>
    """
    header_template = """
      <thead id = '{{headerrowid}}'></thead>
    """
    header_column = """
      <th><a href="javascript:cdxSortByColumn()" class='link'>{{column_name}}</a></th>
    """
    row_template = """
      <tr></tr>
    """
    datacell_template = """
      <td>{{data}}</td>
    """

    header_html = _.template(header_template,
      {'headerrowid' : @tag_id('headerrow')})
    header = $(header_html)
    for colname in @mget('columns')
      html = _.template(header_column, {'column_name' : colname})
      header.append($(html))
    table = $(_.template(table_template, {'tableid' : @tag_id('table')}))
    table.append(header)
    for rowdata in @mget_ref('data_source').get('data')
      row = $(row_template)
      for colname in @mget('columns')
        datacell = $(_.template(datacell_template,
          {'data' : rowdata[colname]}))
        row.append(datacell)
        table.append(row)
    @$el.html(table)
    if @mget('usedialog') and not @$el.is(":visible")
      @add_dialog()

class TableView extends ContinuumView
  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @render)

  render : ->
    super()
    @$el.empty()
    @$el.append("<table></table>")
    @$el.find('table').append("<tr></tr>")
    headerrow = $(@$el.find('table').find('tr')[0])
    for column, idx in ['row'].concat(@mget('columns'))
      elem = $(_.template('<th class="tableelem tableheader">{{ name }}</th>',
        {'name' : column}))
      headerrow.append(elem)
    for row, idx in @mget('data')
      row_elem = $("<tr class='tablerow'></tr>")
      rownum = idx + @mget('data_slice')[0]
      for data in [rownum].concat(row)
        elem = $(_.template("<td class='tableelem'>{{val}}</td>",
          {'val':data}))
        row_elem.append(elem)
      @$el.find('table').append(row_elem)
    @render_pagination()
    if @mget('usedialog') and not @$el.is(":visible")
      @add_dialog()

  render_pagination : ->
    if @mget('offset') > 0
      node = $("<button>first</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(0)
        return false
      )
      node = $("<button>previous</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(_.max([@mget('offset') - @mget('chunksize'), 0]))
        return false
      )

    maxoffset = @mget('total_rows') - @mget('chunksize')
    if @mget('offset') < maxoffset
      node = $("<button>next</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(_.min([
          @mget('offset') + @mget('chunksize'),
          maxoffset]))
        return false
      )
      node = $("<button>last</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(maxoffset)
        return false
      )

class CDXPlotContextView extends DeferredParent
  initialize : (options) ->
    @views = {}
    super(options)

  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @request_render)

  generate_remove_child_callback : (view) ->
    callback = () =>
      newchildren = (x for x in @mget('children') when x.id != view.model.id)
      @mset('children', newchildren)
      return null
    return callback

  build_children : () ->
    @mainlist = $("<ul></ul>")
    @$el.append(@mainlist)
    view_specific_options = []
    for spec, counter in @mget('children')
      model = @model.resolve_ref(spec)
      model.set({'usedialog' : false})
      plotelem = $("<li id='li#{counter}'></li>")
      @mainlist.append(plotelem)
      view_specific_options.push({'el' : plotelem})
    created_views = build_views(@model, @views, @mget('children'), {}, view_specific_options)
    window.pc_created_views = created_views
    window.pc_views = @views
    for view in created_views
      safebind(this, view, 'remove', @generate_remove_child_callback(view))
    return null

  render_deferred_components : (force) ->
    super(force)
    for view in _.values(@views)
      view.render_deferred_components(force)

  render : () ->
    super()
    @build_children()
    return null
  
class InteractiveContextView extends DeferredParent
  # Interactive context keeps track of a bunch of components that we render
  # into dialogs

  initialize : (options) ->
    @views = {}
    super(options)

  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @request_render)

  generate_remove_child_callback : (view) ->
    callback = () =>
      newchildren = (x for x in @mget('children') when x.id != view.model.id)
      @mset('children', newchildren)
      return null
    return callback

  build_children : () ->
    for spec in @mget('children')
      model = @model.resolve_ref(spec)
      model.set({'usedialog' : true})
    created_views = build_views(@model, @views, @mget('children'))
    for view in created_views
      safebind(this, view, 'remove', @generate_remove_child_callback(view))
    return null

  render_deferred_components : (force) ->
    super(force)
    for view in _.values(@views)
      view.render_deferred_components(force)

  render : () ->
    super()
    @build_children()
    return null