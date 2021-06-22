require "./repl"

class Crystal::Repl::LocalVarsGatherer < Crystal::Visitor
  @block : Block?

  getter meta_vars : MetaVars
  getter block_level : Int32

  def initialize(@location : Location, @def : Def)
    @meta_vars = MetaVars.new
    @block_level = 0
  end

  def gather : Nil
    self_var = @def.vars.try &.["self"]?
    @meta_vars["self"] = self_var.clone if self_var

    @def.args.each do |arg|
      var = @def.vars.try &.[arg.name]?
      @meta_vars[var.name] = var.clone if var
    end

    if @def.uses_block_arg? && (block_arg = @def.block_arg)
      block_arg_var = @def.vars.try &.[block_arg.name]?
      @meta_vars[block_arg.name] = block_arg_var.clone if block_arg_var
    end

    @def.body.accept self
  end

  def visit(node : Var)
    location = node.location
    if location && location.line_number >= @location.line_number
      return false
    end

    var =
      if block = @block
        block.vars.try &.[node.name]?
      else
        @def.vars.try &.[node.name]?
      end

    @meta_vars[var.name] = var.clone if var

    false
  end

  def visit(node : Block)
    location = node.location
    end_location = node.end_location

    if location && end_location && !(location.line_number < @location.line_number < end_location.line_number)
      return false
    end

    old_block = @block
    @block = node
    @block_level += 1

    node.args.each &.accept self
    node.body.accept self

    @block = old_block

    false
  end

  def visit(node : ASTNode)
    true
  end
end