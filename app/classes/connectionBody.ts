enum DatabaseType {
  postgres = "postgres",
  mongo = "mongo",
}

export default class ConnectionBody {
  //TODO correct regexp checkers
  private _name = "";
  public get name(): string {
    return this._name;
  }
  public set name(value: string) {
    this._name = value;
  }

  private _host = "";
  public get host(): string {
    return this._host;
  }
  public set host(value: string) {
    this._host = value;
  }

  private _port = 0;
  public get port(): number {
    return this._port;
  }
  public set port(value: number) {
    if (value < 0 || value > 65535)
      throw new TypeError("port should be between 0 and 65535");
    this._port = value;
  }

  private _database = "";
  public get database(): string {
    return this._database;
  }
  public set database(value: string) {
    this._database = value;
  }

  private _enabled = true;
  public get enabled(): boolean {
    return this._enabled;
  }
  public set enabled(value: boolean) {
    this._enabled = value;
  }

  private _login = "";
  public get login(): string {
    return this._login;
  }
  public set login(value: string) {
    if (typeof value !== "string")
      throw new TypeError("login should be string");
    this._login = value;
  }

  private _password = "";
  public get password(): string {
    return this._password;
  }
  public set password(value: string) {
    if (typeof value !== "string")
      throw new TypeError("password should be string");
    this._password = value;
  }

  private _type = DatabaseType.postgres;
  public get type(): DatabaseType {
    return this._type;
  }
  public set type(value: DatabaseType) {
    this._type = value;
  }
}
