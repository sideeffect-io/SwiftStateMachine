import StateMachineCore

public let defaultDumpMediator = Mediator<DumpEvent>()

@available(*, deprecated, renamed: "defaultDumpMediator")
public let dedaultDumpMediator = defaultDumpMediator
