import Step from "./step";

export default class JobBody {
  //TODO correct regexp checkers
  private _name = "";
  public get name(): string {
    return this._name;
  }
  public set name(value: string) {
    this._name = value;
  }

  private _description = "";
  public get description(): string {
    return this._description;
  }
  public set description(value: string) {
    this._description = value;
  }

  private _enabled = true;
  public get enabled(): boolean {
    return this._enabled;
  }
  public set enabled(value: boolean) {
    this._enabled = value;
  }

  private _steps: Array<Step> = [];
  public get steps(): Array<Step> {
    return this._steps;
  }
  public set steps(value: Array<Step>) {
    this._steps = value;
  }

  private _schedules: Array<Record<string, unknown>> = [];
  public get schedules(): Array<Record<string, unknown>> {
    return this._schedules;
  }
  public set schedules(value: Array<Record<string, unknown>>) {
    this._schedules = value;
  }
}
