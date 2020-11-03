Unit ClassStatusProcessamento;

interface

  uses Windows, Classes, Dialogs, SysUtils, Forms, Controls, Graphics, WinSock, ShellAPI,
  math, StdCtrls, ComCtrls;

  type

    TStausProcessamento= Class
      private
        __statusOperacao__ : Boolean;
        __msg__            : string;

        function  getStatusOperacao(): Boolean;
        procedure setStatusOperacao(StatusOp: Boolean);

        function  getMsg(): string;
        procedure setMsg(msg: string);
      public
        {Constroi a classe e massa os parâmetros iniciais}
        constructor create();

        //property status: Boolean read getStatusOperacao write setStatusOperacao;
        property status : Boolean read getStatusOperacao write setStatusOperacao;
        property msg    : string  read getMsg            write setMsg;

    end;

implementation

constructor TStausProcessamento.create();
Begin
  __statusOperacao__ := True;
end;

function TStausProcessamento.getStatusOperacao(): Boolean;
Begin
  Result := __statusOperacao__;
end;

function TStausProcessamento.getMsg(): string;
Begin
  Result := __msg__;
end;

procedure TStausProcessamento.setMsg(msg: string);
Begin
  if not __statusOperacao__ then
    __msg__ := msg;
end;

procedure TStausProcessamento.setStatusOperacao(StatusOp: Boolean);
Begin
  if __statusOperacao__ then
    __statusOperacao__ := StatusOp;
end;


End.
