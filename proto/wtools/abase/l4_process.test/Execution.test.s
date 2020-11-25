( function _Execution_test_s( )
{

'use strict';

let Stream;

if( typeof module !== 'undefined' )
{
  let _ = require( '../../../wtools/Tools.s' );

  _.include( 'wTesting' );
  _.include( 'wFiles' );
  _.include( 'wProcessWatcher' );

  require( '../l4_process/Basic.s' );
  Stream = require( 'stream' );
}

let _global = _global_;
let _ = _global_.wTools;
let Self = {};

/*
experimentIpcDeasync:

| Node |     Windows     |  Linux   |     Mac     |
| ---- | --------------- | -------- | ----------- |
| 10   | Routine timeout | No error | Libuv error |
| 12   | Routine timeout | No error | Libuv error |
| 13   | Routine timeout | No error | Libuv error |
| 14   | Routine timeout | No error | Libuv error |
| 15   | Routine timeout | No error | Libuv error |

Windows - execution hangs and test routine ends with timeout
Linux - test finishes without any errors
Mac - tests ends with libuv error on first or next attempt

Windows:
> node -e process.send(1);setTimeout(()=>{},500)
Failed ( test routine time limit ) TestSuite::Tools.l4.porocess.Execution / TestRoutine::experimentIpcDeasync in 60.527s

Libuv error for v10:
/Users/runner/work/_temp/a1bfa3ef-959c-477d-8436-8dc969ebdc61.sh: line 1:  1091 Segmentation fault: 11  node proto/wtools/abase/l4_process.test/Execution.test.s r:experimentIpcDeasync v:10

Libuv error for v12-15:
Assertion failed: (handle->type == UV_TCP || handle->type == UV_TTY || handle->type == UV_NAMED_PIPE), function uv___stream_fd, file ../deps/uv/src/unix/stream.c, line 1622.
/Users/runner/work/_temp/a3028c88-f26a-43fa-8306-d78bcc207e60.sh: line 1:  1459 Abort trap: 6           node proto/wtools/abase/l4_process.test/Execution.test.s r:experimentIpcDeasync v:10

Related links:
https://github.com/jochemstoel/nodejs-system-sleep/issues/4
https://github.com/abbr/deasync/issues/55#issuecomment-538129355
http://docs.libuv.org/en/v1.x/loop.html#c.uv_run
uv_run() is not reentrant. It must not be called from a callback.
*/

/* to run iteratively

RET=0; until [ ${RET} -ne 0 ]; do
    reset
    taskset 0x1 node wtools/abase/l4_process.test/Execution.test.s rapidity:-1
    RET=$?
    sleep 1
done

RET=0; until [ ${RET} -ne 0 ]; do
    reset
    taskset 0x1 node wtools/abase/l4_process.test/Execution.test.s n:1 v:5 s:0 r:terminateSync
    RET=$?
    sleep 1
done

RET=0; until [ ${RET} -ne 0 ]; do
    reset
    taskset 0x1 node wtools/abase/l4_process.test/Execution.test.s n:1 v:5 s:0 r:startSingleOptionDry
    RET=$?
    sleep 1
done

@echo off
:Loop_start
start /wait /b /affinity 1 node wtools\abase\l4_process.test\Execution.test.s n:1 v:5 s:0 r:terminate
IF %errorlevel% EQU 0 GOTO Loop_start
:Loop_end

*/

/*
@echo off
cls
:Loop_start
node proto/wtools/abase/l4_process.test/Execution.test.s n:1 v:10 s:0 r:terminateDifferentStdio
IF %errorlevel% EQU 0 GOTO Loop_start
:Loop_end
*/

/*
### Modes in which child process terminates after signal:

| Signal  |  Windows   |   Linux    |       Mac        |
| ------- | ---------- | ---------- | ---------------- |
| SIGINT  | spawn,fork | spawn,fork | shell,spawn,fork |
| SIGKILL | spawn,fork | spawn,fork | shell,spawn,fork |

### Test routines and modes that pass test checks:

|        Routine         |  Windows   | Windows + windows-kill |   Linux    |       Mac        |
| ---------------------- | ---------- | ---------------------- | ---------- | ---------------- |
| endStructuralSigint    | spawn,fork | spawn,fork             | spawn,fork | shell,spawn,fork |
| endStructuralSigkill   | spawn,fork | spawn,fork             | spawn,fork | shell,spawn,fork |
| endStructuralTerminate |          |                      | spawn,fork | shell,spawn,fork |
| endStructuralKill      | spawn,fork | spawn,fork             | spawn,fork | shell,spawn,fork |

#### endStructuralTerminate on Windows, without windows-kill

For each mode:
exitCode : 1, exitSignal : null

Child process terminates in modes spawn and fork
Child process continues to work in mode spawn

See: doc/ProcessKillMethodsDifference.md

#### endStructuralTerminate on Windows, with windows-kill

For each mode:
exitCode : 3221225725, exitSignal : null

Child process terminates in modes spawn and fork
Child process continues to work in mode spawn

### Shell mode termination results:

| Signal  | Windows | Linux | MacOS |
| ------- | ------- | ----- | ----- |
| SIGINT  | 0       | 0     | 1     |
| SIGKILL | 0       | 0     | 1     |

0 - Child continues to work
1 - Child is terminated
*/

/*

### Info about event `close`
╔════════════════════════════════════════════════════════════════════════╗
║       mode               ipc          disconnecting      close event ║
╟────────────────────────────────────────────────────────────────────────╢
║       spawn             false             false             true     ║
║       spawn             false             true              true     ║
║       spawn             true              false             true     ║
║       spawn             true              true              false    ║
║       fork              true              false             true     ║
║       fork              true              true              false    ║
║       shell             false             false             true     ║
║       shell             false             true              true     ║
╚════════════════════════════════════════════════════════════════════════╝

Summary:

* Options `stdio` and `detaching` don't affect `close` event.
* Mode `spawn`: IPC is optionable. Event close is not called if disconnected process had IPC enabled.
* Mode `fork` : IPC is always enabled. Event close is not called if process is disconnected.
* Mode `shell` : IPC is not available. Event close is always called.
*/

/*
## Event exit

This section shows when event `exit` of child process is called. The behavior is the same for Windows,Linux and Mac.

╔════════════════════════════════════════════════════════════════════════╗
║       mode               ipc          disconnecting      event exit  ║
╟────────────────────────────────────────────────────────────────────────╢
║       spawn             false             false             true     ║
║       spawn             false             true              true     ║
║       spawn             true              false             true     ║
║       spawn             true              true              true     ║
║       fork              true              false             true     ║
║       fork              true              true              true     ║
║       shell             false             false             true     ║
║       shell             false             true              true     ║
╚════════════════════════════════════════════════════════════════════════╝

Event 'exit' is aways called. Options `stdio` and `detaching` also don't affect `exit` event.
*/

// --
// context
// --

function suiteBegin()
{
  let context = this;
  context.suiteTempPath = _.path.tempOpen( _.path.join( __dirname, '../..' ), 'ProcessBasic' );
}

//

function suiteEnd()
{
  let context = this;
  _.assert( _.strHas( context.suiteTempPath, '/ProcessBasic-' ) )
  _.path.tempClose( context.suiteTempPath );
}

//

function assetFor( test, name )
{
  let context = this;
  let a = test.assetFor( name );

  _.assert( _.routineIs( a.program.head ) );
  _.assert( _.routineIs( a.program.body ) );

  let oprogram = a.program;
  program_body.defaults = a.program.defaults;
  a.program = _.routineUnite( a.program.head, program_body );
  return a;

  /* */

  function program_body( o )
  {
    let locals =
    {
      context : { t0 : context.t0, t1 : context.t1, t2 : context.t2, t3 : context.t3 },
      toolsPath : _.module.resolve( 'wTools' ),
    };
    o.locals = o.locals || locals;
    _.mapSupplement( o.locals, locals );
    _.mapSupplement( o.locals.context, locals.context );
    let programPath = a.path.nativize( oprogram.body.call( a, o ) ); /* zzz : modify a.program()? */
    return programPath;
  }

}

// --
// basic
// --

function startMinimalBasic( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let programPath2 = a.program( program2 );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let o2;
    let o3 =
    {
      outputPiping : 1,
      outputCollecting : 1,
      applyingExitCode : 0,
      throwingExitCode : 1
    }

    let expectedOutput =
`${programPath}:begin
${programPath}:end
`
    ready

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode} only execPath`;

      o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode} execPath+args, null`;

      o2 =
      {
        execPath : mode === `fork` ? null : `node`,
        args : `${programPath}`,
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode} execPath+args, empty string`;

      o2 =
      {
        execPath : mode === `fork` ? `` : `node`,
        args : `${programPath}`,
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode} execPath+args, null, array`;

      o2 =
      {
        execPath : mode === `fork` ? null : `node`,
        args : [ `${programPath}` ],
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode} execPath+args empty string array`;

      o2 =
      {
        execPath : mode === `fork` ? `` : `node`,
        args : [ `${programPath}` ],
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, stdio:pipe`;

      o2 =
      {
        execPath : mode === `fork` ? null : `node`,
        args : `${programPath}`,
        mode,
        stdio : 'pipe'
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, expectedOutput );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode : ${mode}, stdio : ignore`;

      o2 =
      {
        execPath : mode === `fork` ? `` : `node`,
        args : `${programPath}`,
        mode,
        stdio : 'ignore',
        outputCollecting : 0,
        outputPiping : 0,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );
        test.identical( options.output, null );
        return null;
      })
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode : ${mode}, return good code`;

      o2 =
      {
        execPath : mode === `fork` ? `${programPath} exitWithCode : 0` : `node ${programPath} exitWithCode:0`,
        outputCollecting : 1,
        stdio : 'pipe',
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return test.mustNotThrowError( _.process.startMinimal( options ) )
      .then( () =>
      {
        test.true( !options.error );
        test.identical( options.pnd.killed, false );
        test.identical( options.exitCode, 0 );
        test.identical( options.exitSignal, null );
        test.identical( options.pnd.exitCode, 0 );
        test.identical( options.pnd.signalCode, null );
        test.identical( options.state, 'terminated' );
        test.identical( _.strCount( options.output, ':begin' ), 1 );
        test.identical( _.strCount( options.output, ':end' ), 0 );
        return null;
      });
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode : ${mode}, return bad code`;

      o2 =
      {
        execPath : mode === `fork` ? `${programPath} exitWithCode : 1` : `node ${programPath} exitWithCode:1`,
        outputCollecting : 1,
        stdio : 'pipe',
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return test.shouldThrowErrorAsync( _.process.startMinimal( options ),
      ( err, arg ) =>
      {
        test.true( _.errIs( err ) );
        test.identical( err.reason, 'exit code' );
      })
      .then( () =>
      {
        test.true( !!options.error );
        test.identical( options.pnd.killed, false );
        test.identical( options.exitCode, 1 );
        test.identical( options.exitSignal, null );
        test.identical( options.pnd.exitCode, 1 );
        test.identical( options.pnd.signalCode, null );
        test.identical( options.state, 'terminated' );
        test.identical( _.strCount( options.output, ':begin' ), 1 );
        test.identical( _.strCount( options.output, ':end' ), 0 );
        return null;
      });
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode : ${mode}, bad args`;

      o2 =
      {
        execPath : mode === `fork` ? null : `node`,
        args : `${programPath} exitWithCode : 0`,
        outputCollecting : 1,
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );

      return test.shouldThrowErrorAsync( _.process.startMinimal( options ), ( err, arg ) =>
      {
        test.true( _.errIs( err ) );
        test.identical( err.reason, 'exit code' );
      })
      .then( () =>
      {
        test.true( !!options.error );
        test.identical( options.exitCode, 1 );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.identical( _.strCount( options.output, ':begin' ), 0 );
        test.identical( _.strCount( options.output, ':end' ), 0 );
        return null;
      });
    })

    /* */

    .then( function()
    {
      test.case = `mode : ${mode}, stdio : pipe, args : [ 'staging', 'debug' ]`;

      o2 =
      {
        execPath : mode === 'fork' ? programPath2 : 'node ' + programPath2,
        args : [ 'staging', 'debug' ],
        mode,
        stdio : 'pipe'
      }
      return null;
    })
    .then( function( arg )
    {

      var options = _.mapSupplement( null, o2, o3 );

      return _.process.startMinimal( options )
      .then( function()
      {
        test.identical( options.exitCode, 0 );

        if( mode === 'fork' )
        {
          test.identical( options.output, o2.args.join( ' ' ) + '\n' );
          test.identical( options.args2, [ 'staging', 'debug' ] )
        }
        else if( mode === 'shell' )
        {
          test.identical( `${programPath2} ` + options.output, o2.args.join( ' ' ) + '\n' );
          test.identical( options.args2, [ programPath2, '"staging"', '"debug"' ] )
        }
        else
        {
          test.identical( `${programPath2} ` + options.output, o2.args.join( ' ' ) + '\n' );
          test.identical( options.args2, [ programPath2, 'staging', 'debug' ] )
        }

        return null;
      })
    })

    /* */

    .then( function()
    {
      test.case = `mode : ${mode}, incorrect usage of o.execPath`;

      o2 =
      {
        execPath : mode === 'fork' ? program2 :  'node ' + program2,
        args : [ 'staging' ],
        mode,
        stdio : 'pipe'
      }

      var options = _.mapSupplement( null, o2, o3 );

      if( mode === 'fork' ) /* Error in assert 'Expects string or strings {-o.execPath-}, but got Function' */
      return test.shouldThrowErrorSync( () => _.process.startMinimal( options ) );
      else /* Error after launching a process */
      return test.shouldThrowErrorAsync( () => _.process.startMinimal( options ) );
    })

    /* - */

    return ready;
  }

  /* - */

  function program1()
  {
    console.log( `${__filename}:begin` );
    let _ = require( toolsPath );
    let process = _global_.process;

    _.include( 'wProcess' );

    var args = _.process.input();

    if( args.map.exitWithCode !== undefined )
    process.exit( args.map.exitWithCode )

    if( args.map.loop )
    _.time.out( context.t2 ); /* 5000 */

    console.log( `${__filename}:end` );
  }

  function program2()
  {
    console.log( process.argv.slice( 2 ).join( ' ' ) );
  }
}

//

/*

  zzz : investigate please
  test routine shellFork causes

 1: node::DecodeWrite
 2: node::Start
 3: v8::RetainedObjectInfo::~RetainedObjectInfo
 4: uv_loop_size
 5: uv_disable_stdio_inheritance
 6: uv_dlerror
 7: uv_run
 8: node::CreatePlatform
 9: node::CreatePlatform
10: node::Start
11: v8_inspector::protocol::Runtime::API::StackTrace::fromJSONString
12: BaseThreadInitThunk
13: RtlUserThreadStart

*/

function startMinimalFork( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  /* */

  a.ready.then( function()
  {
    test.case = 'no args';

    let o =
    {
      execPath : programPath,
      args : null,
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
    }
    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, 0 );
      test.true( _.strHas( o.output, '[]' ) );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'args';

    let o =
    {
      execPath : programPath,
      args : [ 'arg1', 'arg2' ],
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
    }
    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, 0 );
      test.true( _.strHas( o.output,  `[ 'arg1', 'arg2' ]` ) );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'stdio : ignore';

    let o =
    {
      execPath : programPath,
      args : [ 'arg1', 'arg2' ],
      mode : 'fork',
      stdio : 'ignore',
      outputCollecting : 0,
      outputPiping : 0,
    }

    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, 0 );
      test.identical( o.output, null );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'complex';

    function testApp2()
    {
      console.log( process.argv.slice( 2 ) );
      console.log( process.env );
      console.log( process.cwd() );
      console.log( process.execArgv );
    }

    let programPath = a.program( testApp2 );

    let o =
    {
      execPath : programPath,
      currentPath : a.routinePath,
      env : { 'key1' : 'val' },
      args : [ 'arg1', 'arg2' ],
      interpreterArgs : [ '--no-warnings' ],
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
    }
    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, 0 );
      test.true( _.strHas( o.output,  `[ 'arg1', 'arg2' ]` ) );
      test.true( _.strHas( o.output,  `key1: 'val'` ) );
      test.true( _.strHas( o.output,  a.path.nativize( a.routinePath ) ) );
      test.true( _.strHas( o.output,  `[ '--no-warnings' ]` ) );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'complex + deasync';

    function testApp3()
    {
      console.log( process.argv.slice( 2 ) );
      console.log( process.env );
      console.log( process.cwd() );
      console.log( process.execArgv );
    }

    let programPath = a.program( testApp3 );

    let o =
    {
      execPath :   programPath,
      currentPath : a.routinePath,
      env : { 'key1' : 'val' },
      args : [ 'arg1', 'arg2' ],
      interpreterArgs : [ '--no-warnings' ],
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      sync : 1,
      deasync : 1
    }

    _.process.startMinimal( o );
    debugger
    test.identical( o.exitCode, 0 );
    test.true( _.strHas( o.output,  `[ 'arg1', 'arg2' ]` ) );
    test.true( _.strHas( o.output,  `key1: 'val'` ) );
    test.true( _.strHas( o.output,  a.path.nativize( a.routinePath ) ) );
    test.true( _.strHas( o.output,  `[ '--no-warnings' ]` ) );

    return null;
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'test is ipc works';

    function testApp4()
    {
      process.on( 'message', ( e ) =>
      {
        process.send({ message : 'child received ' + e.message })
        process.exit();
      })
    }

    let programPath = a.program( testApp4 );

    let o =
    {
      execPath :   programPath,
      mode : 'fork',
      stdio : 'pipe',
    }

    let gotMessage;
    let con = _.process.startMinimal( o );

    o.pnd.send({ message : 'message from parent' });
    o.pnd.on( 'message', ( e ) =>
    {
      gotMessage = e.message;
    })

    con.then( function( op )
    {
      test.identical( gotMessage, 'child received message from parent' )
      test.identical( o.exitCode, 0 );
      return null;
    })

    return con;
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'execPath can contain path to js file and arguments';

    let o =
    {
      execPath :   programPath + ' arg0',
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
    }

    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, 0 );
      test.true( _.strHas( o.output,  `[ 'arg0' ]` ) );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'test timeOut';

    function testApp5()
    {
      setTimeout( () =>
      {
        console.log( 'timeOut' );
      }, context.t1 * 5 ) /* 5000 */
    }

    let programPath = a.program( testApp5 );

    let o =
    {
      execPath :   programPath,
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 1,
      timeOut : context.t1, /* 1000 */
    }

    return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )
    .then( function( op )
    {
      test.identical( o.exitCode, null );
      return null;
    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = 'test timeOut';

    function testApp6()
    {
      setTimeout( () =>
      {
        console.log( 'timeOut' );
      }, context.t1 * 5 ) /* 5000 */
    }

    let programPath = a.program( testApp6 );

    let o =
    {
      execPath :   programPath,
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      timeOut : context.t1, /* 1000 */
    }

    return _.process.startMinimal( o )
    .then( function( op )
    {
      test.identical( o.exitCode, null );
      return null;
    })
  })

  return a.ready;

  /* - */

  function program1()
  {
    console.log( process.argv.slice( 2 ) );
  }

}

//

function startMinimalErrorHandling( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let testAppPath2 = a.program( program2 );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( function()
    {
      test.case = `mode : ${ mode }; collecting, verbosity and piping off`;

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        stdio : 'pipe',
        verbosity : 0,
        outputCollecting : 0,
        outputPiping : 0
      }
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )
      .then( function( op )
      {
        test.true( _.errIs( op ) );
        test.true( _.strHas( op.message, 'Process returned exit code' ) )
        test.true( _.strHas( op.message, 'Launched as' ) )
        test.true( _.strHas( op.message, 'Stderr' ) )
        test.true( _.strHas( op.message, 'Error message from child' ) )

        test.notIdentical( o.exitCode, 0 );

        return null;
      })

    })

    /* */

    ready.then( function()
    {
      test.case = `mode : ${ mode }; sync, collecting, verbosity and piping off`;

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        stdio : 'pipe',
        sync : 1,
        deasync : mode === 'fork' ? 1 : 0,
        verbosity : 0,
        outputCollecting : 0,
        outputPiping : 0
      }
      var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, 'Process returned exit code' ) )
      test.true( _.strHas( returned.message, 'Launched as' ) )
      test.true( _.strHas( returned.message, 'Stderr' ) )
      test.true( _.strHas( returned.message, 'Error message from child' ) )

      test.notIdentical( o.exitCode, 0 );

      return null;

    })

    /* */

    ready.then( function()
    {
      test.case = `mode : ${ mode }; stdio ignore, sync, collecting, verbosity and piping off`;

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        stdio : 'ignore',
        sync : 1,
        deasync : mode === 'fork' ? 1 : 0,
        verbosity : 0,
        outputCollecting : 0,
        outputPiping : 0
      }
      var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, 'Process returned exit code' ) )
      test.true( _.strHas( returned.message, 'Launched as' ) )
      test.true( !_.strHas( returned.message, 'Stderr' ) )
      test.true( !_.strHas( returned.message, 'Error message from child' ) )

      test.notIdentical( o.exitCode, 0 );

      return null;

    })

    /* */

    ready.then( function()
    {
      test.case = `mode : ${ mode }; stdio inherit, sync, collecting, verbosity and piping off`;

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        stdio : 'inherit',
        sync : 1,
        deasync : mode === 'fork' ? 1 : 0,
        verbosity : 0,
        outputCollecting : 0,
        outputPiping : 0
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        mode,
        stdio : 'pipe',
        sync : 1,
        deasync : mode === 'fork' ? 1 : 0,
        verbosity : 0,
        outputPiping : 1,
        outputPrefixing : 1,
        outputCollecting : 1,
      }
      var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o2 ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, 'Process returned exit code' ) )
      test.true( _.strHas( returned.message, 'Launched as' ) )
      test.true( _.strHas( returned.message, 'Stderr' ) )
      test.true( _.strHas( returned.message, 'Error message from child' ) )

      test.true( _.strHas( o2.output, 'Process returned exit code' ) )
      test.true( _.strHas( o2.output, 'Launched as' ) )
      test.true( !_.strHas( o2.output, 'Stderr' ) )
      test.true( _.strHas( o2.output, 'Error message from child' ) )

      test.notIdentical( o2.exitCode, 0 );

      return null;

    })

    return ready;
  }

  /* */

  /* ORIGINAL */
  // a.ready.then( function()
  // {
  //   test.case = 'collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   'node ' + testAppPath,
  //     mode : 'spawn',
  //     stdio : 'pipe',
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )
  //   .then( function( op )
  //   {
  //     test.true( _.errIs( op ) );
  //     test.true( _.strHas( op.message, 'Process returned exit code' ) )
  //     test.true( _.strHas( op.message, 'Launched as' ) )
  //     test.true( _.strHas( op.message, 'Stderr' ) )
  //     test.true( _.strHas( op.message, 'Error message from child' ) )

  //     test.notIdentical( o.exitCode, 0 );

  //     return null;
  //   })

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   'node ' + testAppPath,
  //     mode : 'shell',
  //     stdio : 'pipe',
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )
  //   .then( function( op )
  //   {
  //     test.true( _.errIs( op ) );
  //     test.true( _.strHas( op.message, 'Process returned exit code' ) )
  //     test.true( _.strHas( op.message, 'Launched as' ) )
  //     test.true( _.strHas( op.message, 'Stderr' ) )
  //     test.true( _.strHas( op.message, 'Error message from child' ) )

  //     test.notIdentical( o.exitCode, 0 );

  //     return null;
  //   })

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   testAppPath,
  //     mode : 'fork',
  //     stdio : 'pipe',
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )
  //   .then( function( op )
  //   {
  //     test.true( _.errIs( op ) );
  //     test.true( _.strHas( op.message, 'Process returned exit code' ) )
  //     test.true( _.strHas( op.message, 'Launched as' ) )
  //     test.true( _.strHas( op.message, 'Stderr' ) )
  //     test.true( _.strHas( op.message, 'Error message from child' ) )

  //     test.notIdentical( o.exitCode, 0 );

  //     return null;
  //   })

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'sync, collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   'node ' + testAppPath,
  //     mode : 'spawn',
  //     stdio : 'pipe',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

  //   test.true( _.errIs( returned ) );
  //   test.true( _.strHas( returned.message, 'Process returned exit code' ) )
  //   test.true( _.strHas( returned.message, 'Launched as' ) )
  //   test.true( _.strHas( returned.message, 'Stderr' ) )
  //   test.true( _.strHas( returned.message, 'Error message from child' ) )

  //   test.notIdentical( o.exitCode, 0 );

  //   return null;

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'sync, collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   'node ' + testAppPath,
  //     mode : 'shell',
  //     stdio : 'pipe',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

  //   test.true( _.errIs( returned ) );
  //   test.true( _.strHas( returned.message, 'Process returned exit code' ) )
  //   test.true( _.strHas( returned.message, 'Launched as' ) )
  //   test.true( _.strHas( returned.message, 'Stderr' ) )
  //   test.true( _.strHas( returned.message, 'Error message from child' ) )

  //   test.notIdentical( o.exitCode, 0 );

  //   return null;

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'sync, collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   testAppPath,
  //     mode : 'fork',
  //     stdio : 'pipe',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

  //   test.true( _.errIs( returned ) );
  //   test.true( _.strHas( returned.message, 'Process returned exit code' ) )
  //   test.true( _.strHas( returned.message, 'Launched as' ) )
  //   test.true( _.strHas( returned.message, 'Stderr' ) )
  //   test.true( _.strHas( returned.message, 'Error message from child' ) )

  //   test.notIdentical( o.exitCode, 0 );

  //   return null;

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'stdio ignore, sync, collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath :   testAppPath,
  //     mode : 'fork',
  //     stdio : 'ignore',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }
  //   var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

  //   test.true( _.errIs( returned ) );
  //   test.true( _.strHas( returned.message, 'Process returned exit code' ) )
  //   test.true( _.strHas( returned.message, 'Launched as' ) )
  //   test.true( !_.strHas( returned.message, 'Stderr' ) )
  //   test.true( !_.strHas( returned.message, 'Error message from child' ) )

  //   test.notIdentical( o.exitCode, 0 );

  //   return null;

  // })

  // /* */

  // a.ready.then( function()
  // {
  //   test.case = 'stdio inherit, sync, collecting, verbosity and piping off';

  //   let o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     stdio : 'inherit',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputCollecting : 0,
  //     outputPiping : 0
  //   }

  //   a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

  //   let o2 =
  //   {
  //     execPath : testAppPath2,
  //     mode : 'fork',
  //     stdio : 'pipe',
  //     sync : 1,
  //     deasync : 1,
  //     verbosity : 0,
  //     outputPiping : 1,
  //     outputPrefixing : 1,
  //     outputCollecting : 1,
  //   }
  //   var returned = test.shouldThrowErrorSync( () => _.process.startMinimal( o2 ) )

  //   test.true( _.errIs( returned ) );
  //   test.true( _.strHas( returned.message, 'Process returned exit code' ) )
  //   test.true( _.strHas( returned.message, 'Launched as' ) )
  //   test.true( _.strHas( returned.message, 'Stderr' ) )
  //   test.true( _.strHas( returned.message, 'Error message from child' ) )

  //   test.true( _.strHas( o2.output, 'Process returned exit code' ) )
  //   test.true( _.strHas( o2.output, 'Launched as' ) )
  //   test.true( !_.strHas( o2.output, 'Stderr' ) )
  //   test.true( _.strHas( o2.output, 'Error message from child' ) )

  //   test.notIdentical( o2.exitCode, 0 );

  //   return null;

  // })

  // /* */

  // return a.ready;

  /* - */

  function program1()
  {
    throw new Error( 'Error message from child' )
  }

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let op = _.fileProvider.fileRead
    ({
      filePath : _.path.join( __dirname, 'op.json'),
      encoding : 'json'
    });

    _.process.startMinimal( op );

  }

}

// --
// sync
// --

function startMinimalSync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  let modes = [ 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* - */

  function run( mode )
  {
    let o3 =
    {
      outputPiping : 1,
      outputCollecting : 1,
      applyingExitCode : 0,
      throwingExitCode : 1,
      sync : 1,
    }

    /* */

    var expectedOutput = programPath + '\n';
    var o2;

    test.case = `mode : ${ mode }`;
    o2 =
    {
      execPath : 'node ' + programPath,
      mode,
      stdio : 'pipe'
    }

    /* stdio : pipe */

    var options = _.mapSupplement( {}, o2, o3 );
    _.process.startMinimal( options );
    debugger;
    test.identical( options.exitCode, 0 );
    test.identical( options.output, expectedOutput );

    /* stdio : ignore */

    o2.stdio = 'ignore';
    o2.outputCollecting = 0;
    o2.outputPiping = 0;

    var options = _.mapSupplement( {}, o2, o3 );
    _.process.startMinimal( options )
    test.identical( options.exitCode, 0 );
    test.identical( options.output, null );

    /* */

    test.case = `mode : ${ mode }, timeOut`;
    o2 =
    {
      execPath : 'node ' + programPath + ' loop : 1',
      mode,
      stdio : 'pipe',
      timeOut : 2*context.t1
    }

    var options = _.mapSupplement( {}, o2, o3 );
    test.shouldThrowErrorSync( () => _.process.startMinimal( options ) );

    /* */

    test.case = `mode : ${ mode }, return good code`;
    o2 =
    {
      execPath : 'node ' + programPath + ' exitWithCode : 0',
      mode,
      stdio : 'pipe'
    }
    var options = _.mapSupplement( {}, o2, o3 );
    test.mustNotThrowError( () => _.process.startMinimal( options ) )
    test.identical( options.exitCode, 0 );

    /* */

    test.case = `mode : ${ mode }, return exit code 1`;
    o2 =
    {
      execPath : 'node ' + programPath + ' exitWithCode : 1',
      mode,
      stdio : 'pipe'
    }
    var options = _.mapSupplement( {}, o2, o3 );
    test.shouldThrowErrorSync( () => _.process.startMinimal( options ) );
    test.identical( options.exitCode, 1 );

    /* */

    test.case = `mode : ${ mode }, return exit code 2`;
    o2 =
    {
      execPath : 'node ' + programPath + ' exitWithCode : 2',
      mode,
      stdio : 'pipe'
    }
    var options = _.mapSupplement( {}, o2, o3 );
    test.shouldThrowErrorSync( () => _.process.startMinimal( options ) );
    test.identical( options.exitCode, 2 );

    return null;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    let process = _global_.process;

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )

    process.removeAllListeners( 'SIGHUP' );
    process.removeAllListeners( 'SIGINT' );
    process.removeAllListeners( 'SIGTERM' );
    process.removeAllListeners( 'exit' );

    var args = _.process.input();

    if( args.map.exitWithCode )
    process.exit( args.map.exitWithCode )

    if( args.map.loop )
    _.time.out( context.t2 ) /* 5000 */

    console.log( __filename );
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    let process = _global_.process;

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )

    process.removeAllListeners( 'SIGHUP' );
    process.removeAllListeners( 'SIGINT' );
    process.removeAllListeners( 'SIGTERM' );
    process.removeAllListeners( 'exit' );

    var args = _.process.input();

    if( args.map.exitWithCode )
    process.exit( args.map.exitWithCode )

    if( args.map.loop )
    _.time.out( context.t2 ) /* 5000 */

    console.log( __filename );
  }
}

//

function startSingleSyncDeasync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );

  /* ORIGINAL */
  // modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( tops )
  {
    let ready = new _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startSingle
      ({
        execPath : programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      })
    });

    let o3, o2, expectedOutput;

    ready.then( () =>
    {
      o3 =
      {
        outputPiping : 1,
        outputCollecting : 1,
        applyingExitCode : 0,
        throwingExitCode : 1,
        sync : tops.sync,
        deasync : tops.deasync
      }

      expectedOutput = programPath + '\n'

      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, stdio : pipe`;
      o2 =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        stdio : 'pipe'
      }

      var options = _.mapSupplement( {}, o2, o3 );
      var returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.identical( returned.exitCode, 0 );
        test.true( returned === options );
        test.identical( returned, options );
        if( tops.deasync )
        test.identical( returned.pnd.constructor.name, 'ChildProcess' );
        else
        test.identical( returned.pnd.constructor.name, 'Object' );
        return returned;
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
        returned.then( ( op ) =>
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.true( op === options );
          test.identical( op.pnd.constructor.name, 'ChildProcess' );
          test.identical( op.output, expectedOutput );

          return op;
        })

        return returned;
      }

    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, stdio : ignore`;

      o2 =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        stdio : 'ignore',
        outputCollecting : 0,
        outputPiping : 0
      }

      var options = _.mapSupplement( {}, o2, o3 );
      var returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.identical( returned.exitCode, 0 );
        test.true( returned === options );
        test.identical( returned, options );
        if( tops.deasync )
        test.identical( returned.pnd.constructor.name, 'ChildProcess' );
        else
        test.identical( returned.pnd.constructor.name, 'Object' );
        return returned;
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
        returned.then( ( op ) =>
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.true( op === options );
          test.identical( op.pnd.constructor.name, 'ChildProcess' );
          test.identical( op.output, null );

          return op;
        })

        return returned;
      }
    });

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, timeOut`;

      o2 =
      {
        execPath : tops.mode === 'fork' ? programPath + ' loop : 1' : 'node ' + programPath + ' loop : 1',
        mode : tops.mode,
        stdio : 'pipe',
        timeOut : 2*context.t1,
      }

      var options = _.mapSupplement( {}, o2, o3 );

      if( tops.sync )
      return test.shouldThrowErrorSync( () => _.process.startSingle( options ) );
      else
      return test.shouldThrowErrorAsync( () => _.process.startSingle( options ) );
    });

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, return good code`;
      o2 =
      {
        execPath : tops.mode === 'fork' ? programPath + ' exitWithCode : 0' : 'node ' + programPath + ' exitWithCode : 0',
        mode : tops.mode,
        stdio : 'pipe'
      }

      var options = _.mapSupplement( {}, o2, o3 );
      var returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.identical( returned.exitCode, 0 );
        test.true( returned === options );
        test.identical( returned, options );
        if( tops.deasync )
        test.identical( returned.pnd.constructor.name, 'ChildProcess' );
        else
        test.identical( returned.pnd.constructor.name, 'Object' );
        return returned;
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
        returned.then( ( op ) =>
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.true( op === options );
          test.identical( op.pnd.constructor.name, 'ChildProcess' );
          test.identical( op.output, expectedOutput );

          return op;
        })

        return returned;
      }

    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, return good code`;
      o2 =
      {
        execPath : tops.mode === 'fork' ? programPath + ' exitWithCode : 1' : 'node ' + programPath + ' exitWithCode : 1',
        mode : tops.mode,
        stdio : 'pipe'
      }

      var options = _.mapSupplement( {}, o2, o3 );

      if( tops.sync )
      {
        test.shouldThrowErrorSync( () => _.process.startSingle( options ) );
        test.identical( options.exitCode, 1 )

        return options;
      }
      else
      {
        return test.shouldThrowErrorAsync( () => _.process.startSingle( options ) )
        .then( ( op ) =>
        {
          test.true( _.errIs( op ) );
          test.identical( options.exitCode, 1 );

          return null;
        } );

      }

    } )

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    let process = _global_.process;

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )

    process.removeAllListeners( 'SIGHUP' );
    process.removeAllListeners( 'SIGINT' );
    process.removeAllListeners( 'SIGTERM' );
    process.removeAllListeners( 'exit' );

    var args = _.process.input();

    if( args.map.exitWithCode )
    process.exit( args.map.exitWithCode )

    if( args.map.loop )
    _.time.out( context.t1 * 5 ) /* 5000 */

    console.log( __filename );
  }

}

startSingleSyncDeasync.timeOut = 57e4; /* Locally : 56.549s */

//

function startMinimalSyncDeasyncThrowing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let modes = [  'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );

  return a.ready;

  /* */

  function run( tops )
  {
    test.case = `mode : ${ tops.mode }; sync : ${ tops.sync }; deasync : ${ tops.deasync }`;

    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}`
      let o =
      {
        execPath : 'node ' + programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      }

      if( tops.sync )
      {
        test.shouldThrowErrorSync( () =>  _.process.startMinimal( o ) );
        return null;
      }
      else
      {
        var returned = _.process.startMinimal( o );

        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
        return test.shouldThrowErrorAsync( returned );
      }
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    throw new Error( 'Test error' );
  }

}

startMinimalSyncDeasyncThrowing.timeOut = 45000;

//

function startMultipleSyncDeasync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );

  return a.ready;

  /* - */

  function run( sync, deasync, mode )
  {
    test.case = `mode : ${ mode }; sync : ${ sync }; deasync : ${ deasync }`;

    let con = new _.Consequence().take( null );

    if( sync && !deasync && mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startMultiple
      ({ execPath : [ programPath, programPath ],
        mode,
        sync,
        deasync
      })
    });

    con.then( () =>
    {
      let execPath = mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ];
      let o =
      {
        execPath,
        mode,
        sync,
        deasync
      }
      var returned = _.process.startMultiple( o );

      if( sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.true( returned === o );
        test.identical( returned.sessions.length, 2 );
        test.identical( o.sessions[ 0 ].exitCode, 0 );
        test.identical( o.sessions[ 0 ].exitSignal, null );
        test.identical( o.sessions[ 0 ].exitReason, 'normal' );
        test.identical( o.sessions[ 0 ].ended, true );
        test.identical( o.sessions[ 0 ].state, 'terminated' );

        test.identical( o.sessions[ 1 ].exitCode, 0 );
        test.identical( o.sessions[ 1 ].exitSignal, null );
        test.identical( o.sessions[ 1 ].exitReason, 'normal' );
        test.identical( o.sessions[ 1 ].ended, true );
        test.identical( o.sessions[ 1 ].state, 'terminated' );

        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );

        return returned;
      }
      else
      {
        test.true( _.consequenceIs( returned ) );

        if( deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );

        returned.then( function( result )
        {
          // debugger;
          test.true( result === o );
          test.identical( o.sessions.length, 2 );
          test.identical( o.sessions[ 0 ].exitCode, 0 );
          test.identical( o.sessions[ 0 ].exitSignal, null );
          test.identical( o.sessions[ 0 ].exitReason, 'normal' );
          test.identical( o.sessions[ 0 ].ended, true );
          test.identical( o.sessions[ 0 ].state, 'terminated' );

          test.identical( o.sessions[ 1 ].exitCode, 0 );
          test.identical( o.sessions[ 1 ].exitSignal, null );
          test.identical( o.sessions[ 1 ].exitReason, 'normal' );
          test.identical( o.sessions[ 1 ].ended, true );
          test.identical( o.sessions[ 1 ].state, 'terminated' );

          test.identical( o.exitCode, 0 );
          test.identical( o.exitSignal, null );
          test.identical( o.exitReason, 'normal' );
          test.identical( o.ended, true );
          test.identical( o.state, 'terminated' );

          return result;
        })
      }

      return returned;
    })

    return con;
  }

  /* - */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) )
  }
}

// --
// arguments
// --

function startMinimalWithoutExecPath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let counter = 0;
  let time = 0;
  let filePath = a.path.nativize( a.abs( a.routinePath, 'file.txt' ) );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single`;
      time = _.time.now();
      counter = 0;

      return null;
    })

    ready.then( () =>
    {
      let singleOption =
      {
        args : mode === 'fork' ? [ programPath, '1000' ] : [ 'node', programPath, '1000' ],
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      return _.process.startMinimal( singleOption )
      .then( ( arg ) =>
      {
        test.identical( arg.exitCode, 0 );
        test.true( singleOption === arg );
        test.true( _.strHas( arg.output, 'begin 1000' ) );
        test.true( _.strHas( arg.output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    })

    return ready;

  }

  /* ORIGINAL */
  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleOption =
  // {
  //   args : [ 'node', programPath, '1000' ],
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // _.process.startMinimal( singleOption )
  // .then( ( arg ) =>
  // {
  //   test.identical( arg.exitCode, 0 );
  //   test.true( singleOption === arg );
  //   test.true( _.strHas( arg.output, 'begin 1000' ) );
  //   test.true( _.strHas( arg.output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );
  //   counter += 1;
  //   return null;
  // });

  // return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    var ended = 0;
    var fs = require( 'fs' );
    var path = require( 'path' );
    var filePath = path.join( __dirname, 'file.txt' );
    console.log( 'begin', process.argv.slice( 2 ).join( ', ' ) );
    var time = parseInt( process.argv[ 2 ] );
    if( isNaN( time ) )
    throw new Error( 'Expects number' );

    setTimeout( end, time );
    function end()
    {
      ended = 1;
      fs.writeFileSync( filePath, 'written by ' + process.argv[ 2 ] );
      console.log( 'end', process.argv.slice( 2 ).join( ', ' ) );
    }

    setTimeout( periodic, context.t0 / 2 ); /* 50 */
    function periodic()
    {
      console.log( 'tick', process.argv.slice( 2 ).join( ', ' ) );
      if( !ended )
      setTimeout( periodic, context.t0 / 2 ); /* 50 */
    }
  }
}

startMinimalWithoutExecPath.timeOut = 7e4; /* Locally : 6.705s */

//

function startMinimalArgsOption( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, args option as array, source args array should not be changed`;
      var args = [ 'arg1', 'arg2' ];
      var startOptions =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        outputCollecting : 1,
        args,
        mode,
      }

      let con = _.process.startMinimal( startOptions )

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'fork' )
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }
        else if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          test.identical( op.args2, [ programPath, '"arg1"', '"arg2"' ] );
        }
        else
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          test.identical( op.args2, [ programPath, 'arg1', 'arg2' ] );
        }

        test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
        test.identical( startOptions.args, op.args );
        test.identical( args, mode === 'fork' ? [ 'arg1', 'arg2' ] : [ programPath, 'arg1', 'arg2' ] );
        return null;
      })

      return con;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, args option as string`;
      var args = 'arg1'
      var startOptions =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        outputCollecting : 1,
        args,
        mode,
      }

      let con = _.process.startMinimal( startOptions )

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );

        if( mode === 'fork' )
        {
          test.identical( op.args, [ 'arg1' ] );
          test.identical( op.args2, [ 'arg1' ] );
        }
        else if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1' ] );
          test.identical( op.args2, [ programPath, '"arg1"' ] );
        }
        else
        {
          test.identical( op.args, [ programPath, 'arg1' ] );
          test.identical( op.args2, [ programPath, 'arg1' ] );
        }

        test.identical( _.strCount( op.output, 'arg1' ), 1 );
        test.identical( startOptions.args, op.args );
        test.identical( args, 'arg1' );
        return null;
      })

      return con;
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

function startMinimalArgumentsParsing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPathNoSpace = a.program({ routine : testApp, dirPath : a.abs( 'noSpace' ) });
  let testAppPathSpace = a.program({ routine : testApp, dirPath : a.abs( 'with space' ) });

  /* for combination:
      path to exe file : [ with space, without space ]
      execPath : [ has arguments, only path to exe file ]
      args : [ has arguments, empty ]
      mode : [ 'fork', 'spawn', 'shell' ]
  */


  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : with space' 'execPATH : has arguments' 'args has arguments'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' firstArg secondArg:1 "third arg"' : 'node ' + _.strQuote( testAppPathSpace ) + ' firstArg secondArg:1 "third arg"',
        args : [ '\'fourth arg\'',  `"fifth" arg` ],
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;

      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', '\'fourth arg\'', '"fifth" arg' ] )
          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : without space' 'execPATH : has arguments' 'args has arguments'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathNoSpace ) + ' firstArg secondArg:1 "third arg"' : 'node ' + _.strQuote( testAppPathNoSpace ) + ' firstArg secondArg:1 "third arg"',
        args : [ '\'fourth arg\'',  `"fifth" arg` ],
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : with space' 'execPATH : only path' 'args has arguments'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) : 'node ' + _.strQuote( testAppPathSpace ),
        args : [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', `"fifth" arg` ],
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) );
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } );
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', '"fifth" arg' ] );
          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : without space' 'execPATH : only path' 'args has arguments'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathNoSpace ) : 'node ' + _.strQuote( testAppPathNoSpace ),
        args : [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', `"fifth" arg` ],
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', '"third arg"', '\'fourth arg\'', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : with space' 'execPATH : has arguments' 'args: empty'`

      let con = new _.Consequence().take( null );

      let execPathStr = mode === 'shell' ? _.strQuote( testAppPathNoSpace ) + ' firstArg secondArg:1 "third arg" \'fourth arg\' \'"fifth" arg\'' : _.strQuote( testAppPathSpace ) + ' firstArg secondArg:1 "third arg" \'fourth arg\' `"fifth" arg`';

      let o =
      {
        execPath : mode === 'fork' ? execPathStr : 'node ' + execPathStr,
        args : null,
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          /* Windows cmd supports only double quotes as grouping char, single quotes are treated as regular char*/
          if( process.platform === 'win32' )
          {
            test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' 'fifth arg'` } )
            test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', `'fourth`, `arg'`, `'fifth`, `arg'` ] )
          }
          else
          {
            test.identical( op.map, { secondArg : `1 "third arg" "fourth arg" "fifth" arg` } )
            test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', 'fourth arg', '"fifth" arg' ] )
          }

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" "fourth arg" "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', 'fourth arg', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : without space' 'execPATH : has arguments' 'args: empty'`

      let con = new _.Consequence().take( null );
      let execPathStr = mode === 'shell' ? _.strQuote( testAppPathNoSpace ) + ' firstArg secondArg:1 "third arg" \'fourth arg\' \'"fifth" arg\'' : _.strQuote( testAppPathNoSpace ) + ' firstArg secondArg:1 "third arg" \'fourth arg\' `"fifth" arg`';
      let o =
      {
        execPath : mode === 'fork' ? execPathStr : 'node ' + execPathStr,
        args : null,
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          /* Windows cmd supports only double quotes as grouping char, single quotes are treated as regular char*/
          if( process.platform === 'win32' )
          {
            test.identical( op.map, { secondArg : `1 "third arg" 'fourth arg' 'fifth arg'` } )
            test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', `'fourth`, `arg'`, `'fifth`, `arg'` ] )
          }
          else
          {
            test.identical( op.map, { secondArg : '1 "third arg" "fourth arg" "fifth" arg' } )
            test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', 'fourth arg', '"fifth" arg' ] )
          }

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, { secondArg : `1 "third arg" "fourth arg" "fifth" arg` } )
          test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', 'third arg', 'fourth arg', '"fifth" arg' ] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : with space' 'execPATH : only path' 'args: empty'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) : 'node ' + _.strQuote( testAppPathSpace ),
        args : null,
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, {} )
          test.identical( op.scriptArgs, [] )

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, {} )
          test.identical( op.scriptArgs, [] )

          return null;
        })
      }

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, 'path to exec : without space' 'execPATH : only path' 'args: empty'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathNoSpace ) : 'node ' + _.strQuote( testAppPathNoSpace ),
        args : null,
        ipc : mode === 'shell' ? null : 1,
        mode,
        outputPiping : 1,
        outputCollecting : mode === 'shell' ? 1 : 0,
        ready : con
      }
      _.process.startMinimal( o );

      let op;

      if( mode === 'shell' )
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, {} )
          test.identical( op.scriptArgs, [] )

          return null;
        })
      }
      else
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathNoSpace ) )
          test.identical( op.map, {} )
          test.identical( op.scriptArgs, [] )

          return null;
        })
      }

      return con;
    })

    /* */

    /* special case from willbe */

    .then( () =>
    {
      test.case = `mode : ${ mode }, 'path to exec : with space' 'execPATH : only path' 'args: willbe args'`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) : 'node ' + _.strQuote( testAppPathSpace ),
        args : '.imply v:1 ; .each . .resources.list about::name',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      let op;
      if( mode === 'fork' )
      {
        o.pnd.on( 'message', ( e ) => { op = e } )

        con.then( () =>
        {
          debugger;
          test.identical( o.exitCode, 0 );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) );
          test.identical( op.map, { v : 1 } );
          test.identical( op.scriptArgs, [ '.imply v:1 ; .each . .resources.list about::name' ] );

          return null;
        })
      }
      else
      {
        con.then( () =>
        {
          test.identical( o.exitCode, 0 );
          op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { v : 1 } )
          test.identical( op.scriptArgs, [ '.imply v:1 ; .each . .resources.list about::name' ] )

          return null;
        })
      }

      return con;
    })

    return ready;
  }

  /* ORIGINAL */ /* zzz */

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )
    debugger;
    var args = _.process.input();
    if( process.send )
    process.send( args );
    else
    console.log( JSON.stringify( args ) );
  }

}

startMinimalArgumentsParsing.timeOut = 1e5;

//

function startMinimalArgumentsParsingNonTrivial( test )
{
  let context = this;

  let a = context.assetFor( test, false );

  let testAppPathNoSpace = a.program({ routine : testApp, dirPath : a.abs( 'noSpace' ) });
  let testAppPathSpace = a.program({ routine : testApp, dirPath : a.abs( 'with space' ) });

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /*

  execPath : '"/dir with space/app.exe" `firstArg secondArg ":" 1` "third arg" \'fourth arg\'  `"fifth" arg`,
  args : '"some arg"'
  mode : 'spawn'
  ->
  execPath : '/dir with space/app.exe'
  args : [ 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ],

  =

  execPath : '"/dir with space/app.exe" firstArg secondArg:1',
  args : '"third arg"',
  ->
  execPath : '/dir with space/app.exe'
  args : [ 'firstArg', 'secondArg:1', '"third arg"' ]

  =

  execPath : '"first arg"'
  ->
  execPath : 'first arg'
  args : []

  =

  args : '"first arg"'
  ->
  execPath : 'first arg'
  args : []

  =

  args : [ '"first arg"', 'second arg' ]
  ->
  execPath : 'first arg'
  args : [ 'second arg' ]

  =

  args : [ '"', 'first', 'arg', '"' ]
  ->
  execPath : '"'
  args : [ 'first', 'arg', '"' ]

  =

  args : [ '', 'first', 'arg', '"' ]
  ->
  execPath : ''
  args : [ 'first', 'arg', '"' ]

  =

  args : [ '"', '"', 'first', 'arg', '"' ]
  ->
  execPath : '"'
  args : [ '"', 'first', 'arg', '"' ]

  */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${ mode }, args in execPath and args options`

      let con = new _.Consequence().take( null );
      let execPathStr = mode === 'shell' ? _.strQuote( testAppPathSpace ) + ` 'firstArg secondArg \":\" 1' "third arg" 'fourth arg'  '\"fifth\" arg'` : _.strQuote( testAppPathSpace ) + ' `firstArg secondArg ":" 1` "third arg" \'fourth arg\'  `"fifth" arg`';
      let o =
      {
        execPath : mode === 'fork' ? execPathStr : 'node ' + execPathStr,
        args : '"some arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'fork' )
        {
          test.identical( o.execPath, testAppPathSpace );
          test.identical( o.args, [ 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] );
          test.identical( o.args2, [ 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] );
        }
        else if( mode === 'shell' )
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), `'firstArg secondArg \":\" 1'`, `"third arg"`, `'fourth arg'`, `'\"fifth\" arg'`, '\"some arg\"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), `'firstArg secondArg \":\" 1'`, `"third arg"`, `'fourth arg'`, `'\"fifth\" arg'`, '"\\"some arg\\""' ] );
        }
        else
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ testAppPathSpace, 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] );
        }
        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )
        if( mode === 'shell' )
        {
          if( process.platform === 'win32' )
          test.identical( op.scriptArgs, [ `'firstArg`, `secondArg`, ':', `1'`, 'third arg', `'fourth`, `arg'`, `'fifth`, `arg'`, '"some arg"' ] )
          else
          test.identical( op.scriptArgs, [ 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] )
        }
        else
        {
          test.identical( op.scriptArgs, [ 'firstArg secondArg ":" 1', 'third arg', 'fourth arg', '"fifth" arg', '"some arg"' ] )
        }

        return null;
      })

      return con;
    })


    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' firstArg secondArg:1' : 'node ' + _.strQuote( testAppPathSpace ) + ' firstArg secondArg:1',
        args : '"third arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'fork' )
        {
          test.identical( o.execPath, testAppPathSpace );
          test.identical( o.args, [ 'firstArg', 'secondArg:1', '"third arg"' ] );
          test.identical( o.args2, [ 'firstArg', 'secondArg:1', '"third arg"' ] );
        }
        else if( mode === 'shell' )
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'firstArg', 'secondArg:1', '"third arg"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'firstArg', 'secondArg:1', '"\\"third arg\\""' ] );
        }
        else
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ testAppPathSpace, 'firstArg', 'secondArg:1', '"third arg"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'firstArg', 'secondArg:1', '"third arg"' ] );
        }

        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, { secondArg : '1 "third arg"' } )
        test.identical( op.subject, 'firstArg' )
        test.identical( op.scriptArgs, [ 'firstArg', 'secondArg:1', '"third arg"' ] )

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      if( mode === 'shell' && process.platform === 'win32' )
      return null; /* not for windows */

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : '"first arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }
      _.process.startMinimal( o );

      con.finally( ( err, op ) =>
      {

        if( mode === 'spawn' )
        {
          test.true( !!err );
          test.true( _.strHas( err.message, 'first arg' ) )
          test.identical( o.execPath, 'first arg' );
          test.identical( o.args, [] );
          test.identical( o.args2, [] );
        }
        else if( mode === 'fork' )
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'Error: Cannot find module' ) );
          test.identical( o.execPath, mode === 'shell' ? '"first arg"' : 'first arg' );
          test.identical( o.args, [] );
          test.identical( o.args2, [] );
        }
        else
        {
          test.ni( op.exitCode, 0 );
          if( process.platform === 'darwin' )
          test.true( _.strHas( op.output, 'first arg: command not found' ) );
          // else if( process.platform === 'win32' )
          // test.identical
          // (
          //   op.output,
          //   `'"first arg"' is not recognized as an internal or external command,\noperable program or batch file.\n`
          // );
          // test.true( _.strHas( op.output, '"first arg"' ) );
          else
          test.identical( op.output, 'sh: 1: first arg: not found\n' )
        }
        test.identical( o.execPath, mode === 'shell' ? '"first arg"' : 'first arg' );
        test.identical( o.args, [] );
        test.identical( o.args2, [] );

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      if( mode === 'shell' && process.platform === 'win32' )
      return null; /* not for windows */

      let con = new _.Consequence().take( null );
      let o =
      {
        args : [ '"first arg"', 'second arg' ],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }
      _.process.startMinimal( o );

      con.finally( ( err, op ) =>
      {

        if( mode === 'spawn' )
        {
          test.true( !!err );
          test.true( _.strHas( err.message, 'first arg' ) )
          test.identical( o.args2, [ 'second arg' ] );
        }
        else if( mode === 'fork' )
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'Error: Cannot find module' ) );
          test.identical( o.args2, [ 'second arg' ] );
        }
        else
        {
          test.ni( op.exitCode, 0 );
          if( process.platform === 'darwin' )
          test.true( _.strHas( op.output, 'first: command not found' ) );
          // else if( process.platform === 'win32' )
          // test.identical
          // (
          //   op.output,
          //   `'first' is not recognized as an internal or external command,\noperable program or batch file.\n`
          // );
          else
          test.identical( op.output, 'sh: 1: first: not found\n' )
          test.identical( o.args2, [ '"second arg"' ] );
        }
        test.identical( o.execPath, 'first arg' );
        test.identical( o.args, [ 'second arg' ] );

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      if( mode === 'shell' && process.platform === 'win32' )
      return null;
      if( mode === 'fork' )
      return null;

      let con = new _.Consequence().take( null );
      let o =
      {
        args : [ '"', 'first', 'arg', '"' ],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }
      _.process.startMinimal( o );

      con.finally( ( err, op ) =>
      {
        if( mode === 'spawn' )
        {
          test.true( !!err );
          test.true( _.strHas( err.message, '"' ) )
          test.identical( o.args2, [ 'first', 'arg', '"' ] );
        }
        else if( mode === 'fork' )
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, ': command not found' ) );
          test.identical( o.args2, [ 'first', 'arg', '"' ] );
        }
        else
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'unexpected EOF' ) || _.strHas( op.output, 'Unterminated quoted string' ) );
          test.identical( o.args2, [ '"first"', '"arg"', '"\\""' ] );
        }

        test.identical( o.execPath, '"' );
        test.identical( o.args, [ 'first', 'arg', '"' ] );

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      if( mode === 'shell' && process.platform === 'win32' )
      return null; /* not for windows */
      if( mode === 'fork' )
      return null;

      let con = new _.Consequence().take( null );
      let o =
      {
        args : [ '', 'first', 'arg', '"' ],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }
      _.process.startMinimal( o );

      con.finally( ( err, op ) =>
      {

        if( mode === 'spawn' )
        {
          test.true( !!err );
          test.identical( o.execPath, '' );
          test.identical( o.args2, [ 'first', 'arg', '"' ] );
        }
        else if( mode === 'fork' )
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'unexpected EOF while looking for matching' ) );
          test.identical( o.args2, [ 'first', 'arg', '"' ] );
        }
        else
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'not found' ) );
          test.identical( o.args2, [ '"first"', '"arg"', '"\\""' ] );
        }

        test.identical( o.args, [ 'first', 'arg', '"' ] );

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      if( mode === 'shell' && process.platform === 'win32' )
      return null; /* not for windows */
      if( mode === 'fork' )
      return null;

      let con = new _.Consequence().take( null );
      let o =
      {
        args : [ '"', '"', 'first', 'arg', '"' ],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }
      _.process.startMinimal( o );

      con.finally( ( err, op ) =>
      {
        if( mode === 'spawn' )
        {
          test.true( !!err );
          test.true( _.strHas( err.message, `spawn " ENOENT` ) );
          test.identical( o.args2, [ '"', 'first', 'arg', '"' ] );
        }
        else if( mode === 'fork' )
        {
          test.ni( op.exitCode, 0 );
          test.true( _.strHas( op.output, 'unexpected EOF while looking for matching' ) );
          test.identical( o.args2, [ '"', 'first', 'arg', '"' ] );
        }
        else
        {
          test.ni( op.exitCode, 0 );
          if( process.platform === 'darwin' )
          test.true( _.strHas( op.output, 'unexpected EOF while looking for matching' ) );
          // else if( process.platform === 'win32' )
          // test.identical
          // (
          //   op.output,
          //   `'" "' is not recognized as an internal or external command,\noperable program or batch file.\n`
          // );
          else
          test.identical( op.output, 'sh: 1: Syntax error: Unterminated quoted string\n' );
          test.identical( o.args2, [ '"\\""', '"first"', '"arg"', '"\\""' ] );
          // test.true( _.strHas( op.output, '" "' ) );
        }

        test.identical( o.execPath, '"' );
        test.identical( o.args, [ '"', 'first', 'arg', '"' ] );

        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, no execPath, empty args`

      let con = new _.Consequence().take( null );
      let o =
      {
        args : [],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0,
        ready : con
      }

      _.process.startMinimal( o );

      return test.shouldThrowErrorAsync( con );
    })

    /*  */

    .then( () =>
    {
      test.case = `mode : ${mode}, args in execPath and args options`

      let con = new _.Consequence().take( null );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ` "path/key3":'val3'` : 'node ' + _.strQuote( testAppPathSpace ) + ` "path/key3":'val3'`,
        args : [],
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );

        if( mode === 'fork' )
        {
          test.identical( o.execPath, testAppPathSpace );
          test.identical( o.args, [ `"path/key3":'val3'` ] );
          test.identical( o.args2, [ `"path/key3":'val3'` ] );
          test.identical( op.scriptArgs, [ `"path/key3":'val3'` ] )
        }
        else if( mode === 'shell' )
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), `"path/key3":'val3'` ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), `"path/key3":'val3'` ] );
          if( process.platform === 'win32' )
          test.identical( op.scriptArgs, [ `path/key3:'val3'` ] )
          else
          test.identical( op.scriptArgs, [ 'path/key3:val3' ] )
        }
        else
        {
          test.identical( o.execPath, 'node' );
          test.identical( o.args, [ testAppPathSpace, `"path/key3":'val3'` ] );
          test.identical( o.args2, [ testAppPathSpace, `"path/key3":'val3'` ] )
          test.identical( op.scriptArgs, [ `"path/key3":'val3'` ] )
        }

        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, { 'path/key3' : 'val3' } )
        test.identical( op.subject, '' )

        return null;
      })

      return con;
    })

    /*  */

    return ready;
  }

  /* */

  function testApp()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )
    var args = _.process.input();
    console.log( JSON.stringify( args ) );
  }
}

//

function startMinimalArgumentsNestedQuotes( test )
{
  let context = this;

  let a = context.assetFor( test, false );

  let testAppPathSpace = a.program({ routine : testApp, dirPath : a.abs( 'with space' ) });

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${ mode }`;

      let con = new _.Consequence().take( null );

      let args =
      [
        ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
        ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
        ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
      ]
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' ' + args.join( ' ' ) : 'node ' + _.strQuote( testAppPathSpace ) + ' ' + args.join( ' ' ),
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          /*
          This case shows how shell is interpreting backquote on different platforms.
          It can't be used for arguments wrapping on linux/mac:
          https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html
          */
          if( process.platform === 'win32' )
          {
            let op = JSON.parse( o.output );
            test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
            test.identical( op.map, {} )
            let scriptArgs =
            [
              '\'\'s-s\'\'',
              '\'s-d\'',
              '\'`s-b`\'',
              '\'d-s\'',
              'd-d',
              '`d-b`',
              '`\'b-s\'`',
              '\`b-d`',
              '``b-b``'
            ]
            test.identical( op.scriptArgs, scriptArgs )
          }
          else
          {
            test.identical( _.strCount( o.output, 'not found' ), 3 );
          }
        }
        else
        {
          test.identical( o.exitCode, 0 );
          let op = JSON.parse( o.output );
          test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
          test.identical( op.map, {} )
          let scriptArgs =
          [
            `'s-s'`, `"s-d"`, `\`s-b\``,
            `'d-s'`, `"d-d"`, `\`d-b\``,
            `'b-s'`, `"b-d"`, `\`b-b\``,
          ]
          test.identical( op.scriptArgs, scriptArgs )
        }
        return null;
      })

      return con;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${ mode }`;

      let con = new _.Consequence().take( null );
      let args =
      [
        ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
        ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
        ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
      ]
      let o =
      {
        execPath :  mode === 'fork' ? _.strQuote( testAppPathSpace ) : 'node ' + _.strQuote( testAppPathSpace ),
        args : args.slice(),
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        ready : con
      }
      _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )
        test.identical( op.scriptArgs, args )

        return null;
      })

      return con;
    })

    return ready;
  }

  /* */

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'fork'

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' ' + args.join( ' ' ),
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     let scriptArgs =
  //     [
  //       `'s-s'`, `"s-d"`, `\`s-b\``,
  //       `'d-s'`, `"d-d"`, `\`d-b\``,
  //       `'b-s'`, `"b-d"`, `\`b-b\``,
  //     ]
  //     test.identical( op.scriptArgs, scriptArgs )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'fork'

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ),
  //     args : args.slice(),
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, args )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'spawn'

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' ' + args.join( ' ' ),
  //     mode : 'spawn',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     let scriptArgs =
  //     [
  //       `'s-s'`, `"s-d"`, `\`s-b\``,
  //       `'d-s'`, `"d-d"`, `\`d-b\``,
  //       `'b-s'`, `"b-d"`, `\`b-b\``,
  //     ]
  //     test.identical( op.scriptArgs, scriptArgs )

  //     return null;
  //   })

  //   return con;

  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'spawn'

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ),
  //     args : args.slice(),
  //     mode : 'spawn',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, args )

  //     return null;
  //   })

  //   return con;

  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'shell'
  //   /*
  //    This case shows how shell is interpreting backquote on different platforms.
  //    It can't be used for arguments wrapping on linux/mac:
  //    https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html
  //   */

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' ' + args.join( ' ' ),
  //     mode : 'shell',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     if( process.platform === 'win32' )
  //     {
  //       let op = JSON.parse( o.output );
  //       test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //       test.identical( op.map, {} )
  //       let scriptArgs =
  //       [
  //         '\'\'s-s\'\'',
  //         '\'s-d\'',
  //         '\'`s-b`\'',
  //         '\'d-s\'',
  //         'd-d',
  //         '`d-b`',
  //         '`\'b-s\'`',
  //         '\`b-d`',
  //         '``b-b``'
  //       ]
  //       test.identical( op.scriptArgs, scriptArgs )
  //     }
  //     else
  //     {
  //       test.identical( _.strCount( o.output, 'not found' ), 3 );
  //     }

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'shell'

  //   let con = new _.Consequence().take( null );
  //   let args =
  //   [
  //     ` '\'s-s\''  '\"s-d\"'  '\`s-b\`'  `,
  //     ` "\'d-s\'"  "\"d-d\""  "\`d-b\`"  `,
  //     ` \`\'b-s\'\`  \`\"b-d\"\`  \`\`b-b\`\` `,
  //   ]
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ),
  //     args : args.slice(),
  //     mode : 'shell',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, args )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // return a.ready;

  /**/

  function testApp()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )
    var args = _.process.input();
    console.log( JSON.stringify( args ) );
  }
}

//

function startMinimalExecPathQuotesClosing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPathSpace = a.path.nativize( a.path.normalize( a.program({ routine : testApp, dirPath : a.abs( 'with space' ) }) ) );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, quoted arg`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "arg"' : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"arg"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"arg"' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg' );
          test.identical( o.args, [ testAppPathSpace, 'arg' ] );
          test.identical( o.args2, [ testAppPathSpace, 'arg' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' arg' );
          test.identical( o.args, [ 'arg' ] );
          test.identical( o.args2, [ 'arg' ] );
        }
        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )
        test.identical( op.scriptArgs, [ 'arg' ] )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, unquoted arg`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' arg' : 'node ' + _.strQuote( testAppPathSpace ) + ' arg',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' arg' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'arg' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'arg' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg' );
          test.identical( o.args, [ testAppPathSpace, 'arg' ] );
          test.identical( o.args2, [ testAppPathSpace, 'arg' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' arg' );
          test.identical( o.args, [ 'arg' ] );
          test.identical( o.args2, [ 'arg' ] );
        }
        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )
        test.identical( op.scriptArgs, [ 'arg' ] )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, single quote left`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' " arg' : 'node ' + _.strQuote( testAppPathSpace ) + ' " arg',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      if( mode === 'shell' && process.platform !== 'win32' ) /* unexpected EOF while looking for a matching bracket on mac and linux. On windows no error */
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )

      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' " arg' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"', 'arg' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"', 'arg' ] );
          test.identical( op.scriptArgs, [ ' arg' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' " arg' );
          test.identical( o.args, [ testAppPathSpace, '"', 'arg' ] );
          test.identical( o.args2, [ testAppPathSpace, '"', 'arg' ] );
          test.identical( op.scriptArgs, [ '"', 'arg' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' " arg' );
          test.identical( o.args, [ '"', 'arg' ] );
          test.identical( o.args2, [ '"', 'arg' ] );
          test.identical( op.scriptArgs, [ '"', 'arg' ] )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, single quote right`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' arg "' : 'node ' + _.strQuote( testAppPathSpace ) + ' arg "',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      if( mode === 'shell' && process.platform !== 'win32' ) /* unexpected EOF while looking for a matching bracket on mac and linux. On windows no error */
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )

      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' arg "' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'arg', '"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'arg', '"' ] );
          test.identical( op.scriptArgs, [ 'arg', '' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg "' );
          test.identical( o.args, [ testAppPathSpace, 'arg', '"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'arg', '"' ] );
          test.identical( op.scriptArgs, [ 'arg', '"' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' arg "' );
          test.identical( o.args, [ 'arg', '"' ] );
          test.identical( o.args2, [ 'arg', '"' ] );
          test.identical( op.scriptArgs, [ 'arg', '"' ] )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, arg starts with quote : ' "arg'`;

      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "arg' : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, arg starts with quote : ' "arg"arg'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "arg"arg' : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"arg',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return test.mustNotThrowError( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, arg ends with quote : ' arg"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' arg"' : 'node ' + _.strQuote( testAppPathSpace ) + ' arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, arg ends with quote : ' arg"arg"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' arg"arg"' : 'node ' + _.strQuote( testAppPathSpace ) + ' arg"arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' arg"arg"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'arg"arg"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'arg"arg"' ] );
          test.identical( op.scriptArgs, [ 'argarg' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg"arg"' );
          test.identical( o.args, [ testAppPathSpace, 'arg"arg"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'arg"arg"' ] );
          test.identical( op.scriptArgs, [ 'arg"arg"' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' arg"arg"' );
          test.identical( o.args, [ 'arg"arg"' ] );
          test.identical( o.args2, [ 'arg"arg"' ] );
          test.identical( op.scriptArgs, [ 'arg"arg"' ] )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, quoted with different symbols`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ` "arg'` : 'node ' + _.strQuote( testAppPathSpace ) + ` "arg'`,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, quote as part of arg : ' arg"arg'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' arg"arg' : 'node ' + _.strQuote( testAppPathSpace ) + ' arg"arg',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, quote as part of arg : ' "arg"arg"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "arg"arg"' : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"arg"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      if( mode === 'shell' && process.platform !== 'win32' ) /* unexpected EOF while looking for a matching bracket on mac and linux. On windows no error */
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) )

      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"arg"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"arg"arg"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"arg"arg"' ] );
          test.identical( op.scriptArgs, [ 'argarg' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg"arg' );
          test.identical( o.args, [ testAppPathSpace, 'arg"arg' ] );
          test.identical( o.args2, [ testAppPathSpace, 'arg"arg' ] );
          test.identical( op.scriptArgs, [ 'arg"arg' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' arg"arg' );
          test.identical( o.args, [ 'arg"arg' ] );
          test.identical( o.args2, [ 'arg"arg' ] );
          test.identical( op.scriptArgs, [ 'arg"arg' ] )
        }

        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, {} )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' option : "value"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option : "value"' : 'node ' +  _.strQuote( testAppPathSpace ) + ' option : "value"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' option : "value"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'option', ':', '"value"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'option', ':', '"value"' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option : value' );
          test.identical( o.args, [ testAppPathSpace, 'option', ':', 'value' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option', ':', 'value' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option : value' );
          test.identical( o.args, [ 'option', ':', 'value' ] );
          test.identical( o.args2, [ 'option', ':', 'value' ] );
        }

        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, { option : 'value' } )
        test.identical( op.scriptArgs, [ 'option', ':', 'value' ] )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' option:"value with space"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option:"value with space"' : 'node ' + _.strQuote( testAppPathSpace ) + ' option:"value with space"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' option:"value with space"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'option:"value with space"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'option:"value with space"' ] );
          test.identical( op.scriptArgs, [ 'option:value with space' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option:"value with space"' );
          test.identical( o.args, [ testAppPathSpace, 'option:"value with space"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option:"value with space"' ] );
          test.identical( op.scriptArgs, [ 'option:"value with space"' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option:"value with space"' );
          test.identical( o.args, [ 'option:"value with space"' ] );
          test.identical( o.args2, [ 'option:"value with space"' ] );
          test.identical( op.scriptArgs, [ 'option:"value with space"' ] );
        }

        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) );
        test.identical( op.map, { option : 'value with space' } );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' option : "value with space"'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option : "value with space"' : 'node ' + _.strQuote( testAppPathSpace ) + ' option : "value with space"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' option : "value with space"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'option', ':', '"value with space"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'option', ':', '"value with space"' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option : value with space' );
          test.identical( o.args, [ testAppPathSpace, 'option', ':', 'value with space' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option', ':', 'value with space' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option : value with space' );
          test.identical( o.args, [ 'option', ':', 'value with space' ] );
          test.identical( o.args2, [ 'option', ':', 'value with space' ] );
        }
        let op = JSON.parse( o.output );
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, { option : 'value with space' } )
        test.identical( op.scriptArgs, [ 'option', ':', 'value with space' ] )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' option:"value'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option:"value' : 'node ' + _.strQuote( testAppPathSpace ) + ' option:"value',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' "option: "value""'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "option: "value""' : 'node ' + _.strQuote( testAppPathSpace ) + ' "option: "value""',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' "option: "value""' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"option: "value""' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"option: "value""' ] );
          test.identical( op.scriptArgs, [ 'option: value' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option: "value"' );
          test.identical( o.args, [ testAppPathSpace, 'option: "value"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option: "value"' ] );
          test.identical( op.scriptArgs, [ 'option: "value"' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option: "value"' );
          test.identical( o.args, [ 'option: "value"' ] );
          test.identical( o.args2, [ 'option: "value"' ] );
          test.identical( op.scriptArgs, [ 'option: "value"' ] )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
        test.identical( op.map, { option : 'value' } )
        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, option arg with quoted value : ' option : "value'`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option : "value' : 'node ' + _.strQuote( testAppPathSpace ) + ' option : "value',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, double quoted with space inside, same quotes`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' "option: "value with space""' : 'node ' + _.strQuote( testAppPathSpace ) + ' "option: "value with space""',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' "option: "value with space""' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"option: "value', 'with', 'space""' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"option: "value', 'with', 'space""' ] );
          test.identical( op.scriptArgs, [ 'option: value', 'with', 'space' ] )
          test.identical( op.map, {} )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' "option: "value with space""' );
          test.identical( o.args, [ testAppPathSpace, '"option: "value', 'with', 'space""' ] );
          test.identical( o.args2, [ testAppPathSpace, '"option: "value', 'with', 'space""' ] );
          test.identical( op.scriptArgs, [ '"option: "value', 'with', 'space""' ] )
          test.identical( op.map, { option : 'value with space' } )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' "option: "value with space""' );
          test.identical( o.args, [ '"option: "value', 'with', 'space""' ] );
          test.identical( o.args2, [ '"option: "value', 'with', 'space""' ] );
          test.identical( op.scriptArgs, [ '"option: "value', 'with', 'space""' ] )
          test.identical( op.map, { option : 'value with space' } )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, double quoted with space inside, diff quotes`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' `option: "value with space"`' : 'node ' + _.strQuote( testAppPathSpace ) + ' `option: "value with space"`',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        if( mode !== 'shell' ) /* in mode::shell, 'sh: option:: command not found' is added to the log and JSON cannot be parsed properly */
        {
          let op = JSON.parse( o.output );
          test.identical( op.scriptPath, a.path.normalize( testAppPathSpace ) )
          test.identical( op.map, { option : 'value with space' } )
          test.identical( op.scriptArgs, [ 'option: "value with space"' ] )
        }

        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' `option: "value with space"`' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), '`option: "value with space"`' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '`option: "value with space"`' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option: "value with space"' );
          test.identical( o.args, [ testAppPathSpace, 'option: "value with space"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option: "value with space"' ] );
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option: "value with space"' );
          test.identical( o.args, [ 'option: "value with space"' ] );
          test.identical( o.args2, [ 'option: "value with space"' ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, escaped quotes`;
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPathSpace ) + ' option: \\"value with space\\"' : 'node ' + _.strQuote( testAppPathSpace ) + ' option: \\"value with space\\"',
        mode,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.exitCode, 0 );
        let op = JSON.parse( o.output );
        if( mode === 'shell' )
        {
          test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' option: \\"value with space\\"' );
          test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'option:', '\\"value with space\\"' ] );
          test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'option:', '\\"value with space\\"' ] );
          test.identical( op.map, { option : 'value with space' } )
          test.identical( op.scriptArgs, [ 'option:', '"value', 'with', 'space"' ] )
        }
        else if( mode === 'spawn' )
        {
          test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' option: \\"value with space\\"' );
          test.identical( o.args, [ testAppPathSpace, 'option:', '\\"value with space\\"' ] );
          test.identical( o.args2, [ testAppPathSpace, 'option:', '\\"value with space\\"' ] );
          test.identical( op.map, { option : '\\"value with space\\"' } )
          test.identical( op.scriptArgs, [ 'option:', '\\"value with space\\"' ] )
        }
        else
        {
          test.identical( o.fullExecPath, testAppPathSpace + ' option: \\"value with space\\"' );
          test.identical( o.args, [ 'option:', '\\"value with space\\"' ] );
          test.identical( o.args2, [ 'option:', '\\"value with space\\"' ] );
          test.identical( op.map, { option : '\\"value with space\\"' } )
          test.identical( op.scriptArgs, [ 'option:', '\\"value with space\\"' ] )
        }
        test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )

        return null;
      })
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // testcase( 'quoted arg' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "arg"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' arg' );
  //     test.identical( o.args, [ 'arg' ] );
  //     test.identical( o.args2, [ 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"',
  //     mode : 'spawn',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg' );
  //     test.identical( o.args, [ testAppPathSpace, 'arg' ] );
  //     test.identical( o.args2, [ testAppPathSpace, 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"',
  //     mode : 'shell',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' "arg"' );
  //     test.identical( o.args, [ _.strQuote( testAppPathSpace ), '"arg"' ] );
  //     test.identical( o.args2, [ _.strQuote( testAppPathSpace ), '"arg"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // testcase( 'unquoted arg' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' arg' );
  //     test.identical( o.args, [ 'arg' ] );
  //     test.identical( o.args2, [ 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' arg',
  //     mode : 'spawn',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, 'node ' + testAppPathSpace + ' arg' );
  //     test.identical( o.args, [ testAppPathSpace, 'arg' ] );
  //     test.identical( o.args2, [ testAppPathSpace, 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' arg',
  //     mode : 'shell',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' arg' );
  //     test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'arg' ] );
  //     test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // testcase( 'single quote' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' " arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' " arg' );
  //     test.identical( o.args, [ '"', 'arg' ] );
  //     test.identical( o.args2, [ '"', 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ '"', 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // testcase( 'single quote' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' " arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace+ ' " arg' );
  //     test.identical( o.args, [ '"', 'arg' ] );
  //     test.identical( o.args2, [ '"', 'arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ '"', 'arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' arg "',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' arg "' );
  //     test.identical( o.args, [ 'arg', '"' ] );
  //     test.identical( o.args2, [ 'arg', '"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg', '"' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // testcase( 'arg starts with quote' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "arg"arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   return test.mustNotThrowError( _.process.startMinimal( o ) );
  // })

  // /* */

  // testcase( 'arg ends with quote' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' arg"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }

  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' arg"arg"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o )

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' arg"arg"' );
  //     test.identical( o.args, [ 'arg"arg"' ] );
  //     test.identical( o.args2, [ 'arg"arg"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg"arg"' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // testcase( 'quoted with different symbols' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ` "arg'`,
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // /* */

  // testcase( 'quote as part of arg' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' arg"arg',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }

  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "arg"arg"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' arg"arg' );
  //     test.identical( o.args, [ 'arg"arg' ] );
  //     test.identical( o.args2, [ 'arg"arg' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, {} )
  //     test.identical( op.scriptArgs, [ 'arg"arg' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // testcase( 'option arg with quoted value' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' option : "value"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' option : value' );
  //     test.identical( o.args, [ 'option', ':', 'value' ] );
  //     test.identical( o.args2, [ 'option', ':', 'value' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value' } )
  //     test.identical( op.scriptArgs, [ 'option', ':', 'value' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' option:"value with space"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' option:"value with space"' );
  //     test.identical( o.args, [ 'option:"value with space"' ] );
  //     test.identical( o.args2, [ 'option:"value with space"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value with space' } )
  //     test.identical( op.scriptArgs, [ 'option:"value with space"' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' option : "value with space"',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' option : value with space' );
  //     test.identical( o.args, [ 'option', ':', 'value with space' ] );
  //     test.identical( o.args2, [ 'option', ':', 'value with space' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value with space' } )
  //     test.identical( op.scriptArgs, [ 'option', ':', 'value with space' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' option:"value',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }

  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "option: "value""',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' option: "value"' );
  //     test.identical( o.args, [ 'option: "value"' ] );
  //     test.identical( o.args2, [ 'option: "value"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value' } )
  //     test.identical( op.scriptArgs, [ 'option: "value"' ] )
  //     return null;
  //   })

  //   return con;
  // })

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' option : "value',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );
  // })

  // /* */

  // testcase( 'double quoted with space inside, same quotes' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' "option: "value with space""',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' "option: "value with space""' );
  //     test.identical( o.args, [ '"option: "value', 'with', 'space""' ] );
  //     test.identical( o.args2, [ '"option: "value', 'with', 'space""' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value with space' } )
  //     test.identical( op.scriptArgs,  [ '"option: "value', 'with', 'space""' ] )

  //     return null;
  //   })

  //   return con
  // })

  // /* */

  // testcase( 'double quoted with space inside, diff quotes' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : _.strQuote( testAppPathSpace ) + ' `option: "value with space"`',
  //     mode : 'fork',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, testAppPathSpace + ' option: "value with space"' );
  //     test.identical( o.args, [ 'option: "value with space"' ] );
  //     test.identical( o.args2, [ 'option: "value with space"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value with space' } )
  //     test.identical( op.scriptArgs, [ 'option: "value with space"' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // testcase( 'escaped quotes, mode shell' )

  // .then( () =>
  // {
  //   let con = new _.Consequence().take( null );
  //   let o =
  //   {
  //     execPath : 'node ' + _.strQuote( testAppPathSpace ) + ' option: \\"value with space\\"',
  //     mode : 'shell',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     ready : con
  //   }
  //   _.process.startMinimal( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 );
  //     test.identical( o.fullExecPath, 'node ' + _.strQuote( testAppPathSpace ) + ' option: \\"value with space\\"' );
  //     test.identical( o.args, [ _.strQuote( testAppPathSpace ), 'option:', '\\"value with space\\"' ] );
  //     test.identical( o.args2, [ _.strQuote( testAppPathSpace ), 'option:', '\\"value with space\\"' ] );
  //     let op = JSON.parse( o.output );
  //     test.identical( op.scriptPath, _.path.normalize( testAppPathSpace ) )
  //     test.identical( op.map, { option : 'value with space' } )
  //     test.identical( op.scriptArgs, [ 'option:', '"value', 'with', 'space"' ] )

  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // return a.ready;

  // function testcase( src )
  // {
  //   a.ready.then( () =>
  //   {
  //     test.case = src;
  //     return null;
  //   })
  //   return a.ready;
  // }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wStringsExtra' )
    var args = _.process.input();
    console.log( JSON.stringify( args ) );
  }
}

startMinimalExecPathQuotesClosing.timeOut = 34e4; /* Locally : 33.996s */

//

function startMinimalExecPathSeveralCommands( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( app );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, quoted`;
      let o =
      {
        execPath : mode === 'fork' ? '"app.js arg1 && app.js arg2"' : '"node app.js arg1 && node app.js arg2"',
        mode,
        currentPath : a.routinePath,
        outputPiping : 1,
        outputCollecting : 1,
      }

      return test.shouldThrowErrorAsync( _.process.startMinimal( o ) );

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, no quotes`;
      let o =
      {
        execPath : mode === 'fork' ? 'app.js arg1 && app.js arg2' : 'node app.js arg1 && node app.js arg2',
        mode,
        currentPath : a.routinePath,
        outputPiping : 1,
        outputCollecting : 1,
      }
      return _.process.startMinimal( o )
      .then( ( op ) =>
      {
        test.identical( o.exitCode, 0 );
        if( mode === 'shell' )
        {
          test.identical( _.strCount( op.output, `[ 'arg1' ]` ), 1 );
          test.identical( _.strCount( op.output, `[ 'arg2' ]` ), 1 );
        }
        else if( mode === 'spawn' )
        {
          test.identical( _.strCount( op.output, `[ 'arg1', '&&', 'node', 'app.js', 'arg2' ]` ), 1 );
        }
        else
        {
          test.identical( _.strCount( op.output, `[ 'arg1', '&&', 'app.js', 'arg2' ]` ), 1 );
        }
        return null;
      })
    })

    return ready;
  }

  function app()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

/* qqq for Yevhen : name and split cases */
function startExecPathNonTrivialModeShell( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.path.nativize( a.path.normalize( a.program( app ) ) );

  let shell = _.process.starter
  ({
    mode : 'shell',
    currentPath : a.routinePath,
    outputPiping : 1,
    outputCollecting : 1,
    ready : a.ready
  })

  /* */

  a.ready.then( () =>
  {
    test.open( 'two commands' );
    return null;
  })

  shell( 'node -v && node -v' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 2 );
    return null;
  })

  shell({ execPath : '"node -v && node -v"', throwingExitCode : 0 })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 0 );
    return null;
  })

  shell({ execPath : 'node -v && "node -v"', throwingExitCode : 0 })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  shell({ args : 'node -v && node -v' })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 2 );
    return null;
  })

  shell({ args : '"node -v && node -v"' })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 2 );
    return null;
  })

  shell({ args : [ 'node -v && node -v' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 2 );
    return null;
  })

  shell({ args : [ 'node', '-v', '&&', 'node', '-v' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  shell({ args : [ 'node', '-v', ' && ', 'node', '-v' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  shell({ args : [ 'node -v', '&&', 'node -v' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  a.ready.then( () =>
  {
    test.close( 'two commands' );
    return null;
  })

  /*  */

  a.ready.then( () =>
  {
    test.open( 'argument with space' );
    return null;
  })

  shell( 'node ' + testAppPath + ' arg with space' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg', 'with', 'space' ]` ), 1 );
    return null;
  })

  shell( 'node ' + testAppPath + ' "arg with space"' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg with space' ]` ), 1 );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : 'arg with space' })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg with space' ]` ), 1 );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : [ 'arg with space' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg with space' ]` ), 1 );
    return null;
  })

  shell( 'node ' + testAppPath + ' `"quoted arg with space"`' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.identical( _.strCount( op.output, `[ '\`quoted arg with space\`' ]` ), 1 );
    else
    test.identical( _.strCount( op.output, `not found` ), 1 );
    return null;
  })

  shell( 'node ' + testAppPath + ` \\\`'quoted arg with space'\\\`` )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    let args = a.fileProvider.fileRead({ filePath : a.abs( a.routinePath, 'args' ), encoding : 'json' });
    if( process.platform === 'win32' )
    test.identical( args, [ '\\`\'quoted', 'arg', 'with', 'space\'\\`' ] );
    else
    test.identical( args, [ '`quoted arg with space`' ] );
    return null;
  })

  shell( 'node ' + testAppPath + ` '\`quoted arg with space\`'` )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    let args = a.fileProvider.fileRead({ filePath : a.abs( a.routinePath, 'args' ), encoding : 'json' });
    if( process.platform === 'win32' )
    test.identical( args, [ `\'\`quoted`, 'arg', 'with', `space\`\'` ] );
    else
    test.identical( _.strCount( op.output, `[ '\`quoted arg with space\`' ]` ), 1 );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : '"quoted arg with space"' })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ '"quoted arg with space"' ]` ), 1 );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : '`quoted arg with space`' })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ '\`quoted arg with space\`' ]` ), 1 );
    return null;
  })

  a.ready.then( () =>
  {
    test.close( 'argument with space' );
    return null;
  })

  /*  */

  a.ready.then( () =>
  {
    test.open( 'several arguments' );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath + ` arg1 "arg2" "arg 3" "'arg4'"` })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    let args = a.fileProvider.fileRead({ filePath : a.abs( a.routinePath, 'args' ), encoding : 'json' });
    test.identical( args, [ 'arg1', 'arg2', 'arg 3', `'arg4'` ] );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : `arg1 "arg2" "arg 3" "'arg4'"` })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    let args = a.fileProvider.fileRead({ filePath : a.abs( a.routinePath, 'args' ), encoding : 'json' });
    test.identical( args, [ `arg1 "arg2" "arg 3" "\'arg4\'"` ] );
    return null;
  })

  shell({ execPath : 'node ' + testAppPath, args : [ `arg1`, '"arg2"', `arg 3`, `'arg4'` ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    let args = a.fileProvider.fileRead({ filePath : a.abs( a.routinePath, 'args' ), encoding : 'json' });
    test.identical( args, [ 'arg1', '"arg2"', 'arg 3', `'arg4'` ] );
    return null;
  })

  a.ready.then( () =>
  {
    test.close( 'several arguments' );
    return null;
  })

  /*  */

  shell({ execPath : 'echo', args : [ 'a b', '*', 'c' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, `"a b" "*" "c"` ) );
    else
    test.true( _.strHas( op.output, `a b * c` ) );
    test.identical( op.execPath, 'echo' )
    test.identical( op.args, [ 'a b', '*', 'c' ] );
    test.identical( op.args2, [ '"a b"', '"*"', '"c"' ] );
    test.identical( op.fullExecPath, 'echo "a b" "*" "c"' )
    return null;
  })

  return a.ready;

  /* - */

  function app()
  {
    var fs = require( 'fs' );
    fs.writeFileSync( 'args', JSON.stringify( process.argv.slice( 2 ) ) )
    console.log( process.argv.slice( 2 ) )
  }
}

//

function startArgumentsHandlingTrivial( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  a.fileProvider.fileWrite( a.abs( a.routinePath, 'file' ), 'file' );

  /* */

  let shell = _.process.starter
  ({
    currentPath : a.routinePath,
    mode : 'shell',
    stdio : 'pipe',
    outputPiping : 1,
    outputCollecting : 1,
    ready : a.ready
  })

  /* */

  shell({ execPath : 'echo *' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, `*` ) );
    else
    test.true( _.strHas( op.output, `file` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '*' ] );
    test.identical( op.args2, [ '*' ] );
    test.identical( op.fullExecPath, 'echo *' );
    return null;
  })

  /* */

  return a.ready;
}

//

function startArgumentsHandling( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  a.fileProvider.fileWrite( a.abs( a.routinePath, 'file' ), 'file' );

  /* */

  let shell = _.process.starter
  ({
    currentPath : a.routinePath,
    mode : 'shell',
    stdio : 'pipe',
    outputPiping : 1,
    outputCollecting : 1,
    ready : a.ready
  })

  /* */

  shell({ execPath : 'echo *' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, `*` ) );
    else
    test.true( _.strHas( op.output, `file` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '*' ] );
    test.identical( op.args2, [ '*' ] );
    test.identical( op.fullExecPath, 'echo *' );
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : '*' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `*` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '*' ] );
    test.identical( op.args2, [ '"*"' ] );
    test.identical( op.fullExecPath, 'echo "*"' );
    return null;
  })

  /* */

  shell( `echo "*"` )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `*` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '"*"' ] );
    test.identical( op.args2, [ '"*"' ] );
    test.identical( op.fullExecPath, 'echo "*"' );

    return null;
  })

  /* */

  shell({ execPath : 'echo "a b" "*" c' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, `"a b" "*" c` ) );
    else
    test.true( _.strHas( op.output, `a b * c` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '"a b"', '"*"', 'c' ] );
    test.identical( op.args2, [ '"a b"', '"*"', 'c' ] );
    test.identical( op.fullExecPath, 'echo "a b" "*" c' );
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : [ 'a b', '*', 'c' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, `"a b" "*" "c"` ) );
    else
    test.true( _.strHas( op.output, `a b * c` ) );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ 'a b', '*', 'c' ] );
    test.identical( op.args2, [ '"a b"', '"*"', '"c"' ] );
    test.identical( op.fullExecPath, 'echo "a b" "*" "c"' );
    return null;
  })

  /* */

  shell( `echo '"*"'` )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, '"*"' ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ `'"*"'` ] );
    test.identical( op.args2, [ `'"*"'` ] );
    test.identical( op.fullExecPath, `echo '"*"'` );
    return null;
  })

  /* */

  shell({ execPath : `echo`, args : [ `'"*"'` ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.identical( _.strCount( op.output, `"'\\"*\\"'"` ), 1 );
    else
    test.identical( _.strCount( op.output, '"*"' ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ `'"*"'` ] );
    test.identical( op.args2, [ `"'\\"*\\"'"` ] );
    test.identical( op.fullExecPath, `echo "'\\"*\\"'"` );
    return null;
  })

  /* */

  shell( `echo "'*'"` )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `'*'` ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ `"'*'"` ] );
    test.identical( op.args2, [ `"'*'"` ] );
    test.identical( op.fullExecPath, `echo "'*'"` );
    return null;
  })

  /* */

  shell({ execPath : `echo`, args : [ `"'*'"` ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `'*'` ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ `"'*'"` ] );
    test.identical( op.args2, [ `"\\"'*'\\""` ] );
    test.identical( op.fullExecPath, `echo "\\"'*'\\""` );
    return null;
  })

  /* */

  shell( 'echo `*`' )
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.identical( _.strCount( op.output, '`*`' ), 1 );
    else
    test.identical( _.strCount( op.output, 'Usage:' ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '`*`' ] );
    test.identical( op.args2, [ '`*`' ] );
    test.identical( op.fullExecPath, 'echo `*`' );
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : [ '`*`' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, '`*`' ), 1 );
    test.identical( op.execPath, 'echo' );
    test.identical( op.args, [ '`*`' ] );
    if( process.platform === 'win32' )
    {
      test.identical( op.args2, [ '"`*`"' ] );
      test.identical( op.fullExecPath, 'echo "`*`"' )
    }
    else
    {
      test.identical( op.args2, [ '"\\`*\\`"' ] );
      test.identical( op.fullExecPath, 'echo "\\`*\\`"' )
    }
    return null;
  })

  /* */

  shell({ execPath : `node -e "console.log( process.argv.slice( 1 ) )"`, args : [ 'a b c' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `a b c` ) );
    return null;
  })

  /* */

  shell({ execPath : `node -e "console.log( process.argv.slice( 1 ) )"`, args : [ '"a b c"' ] })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `"a b c"` ) );
    test.identical( op.execPath, 'node' );
    test.identical( op.args, [ '-e', '"console.log( process.argv.slice( 1 ) )"', '"a b c"' ] );
    test.identical( op.args2, [ '-e', '"console.log( process.argv.slice( 1 ) )"', '"\\"a b c\\""' ] );
    test.identical( op.fullExecPath, 'node -e "console.log( process.argv.slice( 1 ) )" "\\"a b c\\""' );
    return null;
  })

  /* */

  return a.ready;
}

//

function startImportantExecPath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  var printArguments = 'node -e "console.log( process.argv.slice( 1 ) )"'

  a.fileProvider.fileWrite( a.abs( a.routinePath, 'file' ), 'file' );

  /* */

  let shell = _.process.starter
  ({
    currentPath : a.routinePath,
    mode : 'shell',
    stdio : 'pipe',
    outputPiping : 1,
    outputCollecting : 1,
    ready : a.ready
  })

  /* */

  shell({ execPath : null, args : [ 'node', '-v', '&&', 'node', '-v' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  /* */

  shell({ execPath : 'node', args : [ '-v', '&&', 'node', '-v' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  /* */

  shell({ execPath : printArguments, args : [ 'a', '&&', 'node', 'b' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `[ 'a', '&&', 'node', 'b' ]` ) )
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : [ '-v', '&&', 'echo', '-v' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, '"-v" "&&" "echo" "-v"' ) )
    else
    test.true( _.strHas( op.output, '-v && echo -v' ) )
    return null;
  })

  /* */

  shell({ execPath : 'node -v && node -v', args : [] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 2 );
    return null;
  })

  /* */

  shell({ execPath : `node -v "&&" node -v`, args : [] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, process.version ), 1 );
    return null;
  })

  /* */

  shell({ execPath : `echo -v "&&" node -v`, args : [] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, '-v "&&" node -v'  ) );
    else
    test.true( _.strHas( op.output, '-v && node -v'  ) );
    return null;
  })

  /* */

  shell({ execPath : null, args : [ 'echo', '*' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, '*' ), 1 );
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : [ '*' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, '*' ), 1 );
    return null;
  })

  /* */

  shell({ execPath : 'echo *' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.identical( _.strCount( op.output, '*' ), 1 );
    else
    test.identical( _.strCount( op.output, 'file' ), 1 );
    return null;
  })

  /* */

  shell({ execPath : 'echo "*"' })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, '*' ), 1 );
    return null;
  })

  /* */

  shell({ execPath : null, args : [ printArguments, 'a b' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `[ 'a b' ]` ) );
    return null;
  })

  /* */

  shell({ execPath : printArguments, args : [ 'a b' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `[ 'a b' ]` ) );
    return null;
  })

  /* */

  shell({ execPath : `${printArguments} a b` })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `[ 'a', 'b' ]` ) );
    return null;
  })

  /* */

  shell({ execPath : `${printArguments} "a b"` })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, `[ 'a b' ]` ) );
    return null;
  })

  /* */

  shell({ execPath : null, args : [ 'echo', '"*"' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( _.strHas( op.output, '*' ) );
    return null;
  })

  /* */

  shell({ execPath : 'echo', args : [ '"*"' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, '\\"*\\"' ) );
    else
    test.true( _.strHas( op.output, '"*"' ) );
    return null;
  })

  /* */

  shell({ execPath : null, args : [ 'echo', '\\"*\\"' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, '\\"*\\"' ) );
    else
    test.true( _.strHas( op.output, '"*"' ) );
    return null;
  })

  /* */

  shell({ execPath : 'echo "\\"*\\""', args : [] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    test.true( _.strHas( op.output, '"\\"*\\"' ) );
    else
    test.true( _.strHas( op.output, '"*"' ) );
    return null;
  })

  /* */

  shell({ execPath : 'echo *', args : [ '*' ] })
  .then( function( op )
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    if( process.platform === 'win32' )
    {
      test.true( _.strHas( op.output, '*' ) );
      test.true( _.strHas( op.output, '"*"' ) );
    }
    else
    {
      test.true( _.strHas( op.output, 'file' ) );
      test.true( _.strHas( op.output, '*' ) );
    }
    return null;
  })

  /* */

  return a.ready;
}

startImportantExecPath.description =
`
exec paths with special chars
`

//

function startMinimalImportantExecPathPassingThrough( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  a.ready.then( () =>
  {
    test.open( '0 args to parent' );
    return null;
  } )

  a.ready.then( function()
  {
    test.case = `execPath : 'echo', args : null`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo', args : null, passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = `execPath : null, args : [ 'echo' ]`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : null, args : [ 'echo' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = `shell({ execPath : 'echo *', args : [ '*' ], passingThrough : 1 })`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo *', args : [ '*' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo * "*"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  a.ready.then( () =>
  {
    test.close( '0 args to parent' );
    return null;
  } )

  /* - */

  a.ready.then( () =>
  {
    test.open( '1 arg to parent' );
    return null;
  } )

  /* ORIGINAL */
  // shell({ execPath : 'echo', args : null, passingThrough : 1 })
  // .then( function( op )
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   if( process.platform === 'win32' )
  //   test.true( _.strHas( op.output, '"' + process.argv.slice( 2 ).join( '" "' ) + '"' ) );
  //   else
  //   test.true( _.strHas( op.output, process.argv.slice( 2 ).join( ' ') ) );
  //   return null;
  // })

  /* REWRITTEN */
  /* PASSING */
  a.ready.then( function()
  {
    test.case = `execPath : 'echo', args : null`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo', args : null, passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : 'argFromParent',
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo "argFromParent"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* ORIGINAL */
  // shell({ execPath : null, args : [ 'echo' ], passingThrough : 1 })
  // .then( function( op )
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   if( process.platform === 'win32' )
  //   test.true( _.strHas( op.output, '"' + process.argv.slice( 2 ).join( '" "' ) + '"' ) );
  //   else
  //   test.true( _.strHas( op.output, process.argv.slice( 2 ).join( ' ') ) );
  //   return null;
  // })

  /* REWRITTEN */
  /* PASSING */
  a.ready.then( function()
  {
    test.case = `execPath : null, args : [ 'echo' ]`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : null, args : [ 'echo' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : 'argFromParent',
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo "argFromParent"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* ORIGINAL */
  // shell({ execPath : 'echo *', args : [ '*' ], passingThrough : 1 })
  // .then( function( op )
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   if( process.platform === 'win32' )
  //   {
  //     test.true( _.strHas( op.output, '*' ) );
  //     test.true( _.strHas( op.output, '"*"' ) );
  //     test.true( _.strHas( op.output, '"' + process.argv.slice( 2 ).join( '" "' ) + '"' ) );
  //   }
  //   else
  //   {
  //     test.true( _.strHas( op.output, 'file' ) );
  //     test.true( _.strHas( op.output, '*' ) );
  //     test.true( _.strHas( op.output, process.argv.slice( 2 ).join( ' ') ) );
  //   }
  //   return null;
  // })

  /* REWRITTEN */
  a.ready.then( function()
  {
    test.case = `execPath : 'echo *', args : *`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo *', args : [ '*' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : 'argFromParent',
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo * "*" "argFromParent"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  a.ready.then( () =>
  {
    test.close( '1 arg to parent' );
    return null;
  } )

  /* - */

  a.ready.then( () =>
  {
    test.open( '2 args to parent' );
    return null;
  } )

  a.ready.then( function()
  {
    test.case = `execPath : 'echo', args : null`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo', args : null, passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : [ 'argFromParent1', 'argFromParent2' ],
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo "argFromParent1" "argFromParent2"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = `execPath : null, args : [ 'echo' ]`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : null, args : [ 'echo' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : [ 'argFromParent1', 'argFromParent2' ],
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo "argFromParent1" "argFromParent2"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  /* */

  a.ready.then( function()
  {
    test.case = `execPath : 'echo *', args : *`;

    let locals =
    {
      routinePath : a.routinePath,
      options : { execPath : 'echo *', args : [ '*' ], passingThrough : 1 }
    }

    let programPath = a.program({ routine : testAppParent, locals });

    let options =
    {
      execPath :  'node ' + programPath,
      outputCollecting : 1,
      args : [ 'argFromParent1', 'argFromParent2' ],
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, 'echo * "*" "argFromParent1" "argFromParent2"\n' ) );

      a.fileProvider.fileDelete( programPath );
      return null;

    })
  })

  a.ready.then( () =>
  {
    test.close( '2 args to parent' );
    return null;
  } )

  return a.ready;

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let shell = _.process.starter
    ({
      currentPath : routinePath,
      mode : 'shell',
      stdio : 'pipe',
      outputPiping : 0,
    })
    return shell( options )
  }


}

//

function startNjsPassingThroughDifferentTypesOfPaths( test )
{
  let context = this;
  let a = context.assetFor( test, 'basic' );
  let testAppPathParent = a.program( testAppParent );
  let testAppPath = a.program( testApp );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execute simple js program with normalized path`

      let execPath = a.path.nativize( a.path.normalize( testAppPath ) );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( execPath ) : 'node ' + _.strQuote( execPath ),
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 1,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      };
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, '[]' );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        return null;
      } )

      /* ORIGINAL */
      // return _.process.startNjsPassingThrough( o )
      // .then( ( op ) =>
      // {
      //   test.identical( op.exitCode, 0 );
      //   test.identical( op.ended, true );
      //   test.true( a.fileProvider.fileExists( testAppPath ) );
      //   test.true( !_.strHas( op.output, `Error: Cannot find module` ) );
      //   return null;
      // })

    });

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execute simple js program with nativized path`

      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPath ) : 'node ' + _.strQuote( testAppPath ),
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 1,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      };

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, '[]' );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        return null;
      } )

      /* ORIGINAL */
      // return _.process.startNjsPassingThrough( o )
      // .then( ( op ) =>
      // {
      //   test.identical( op.exitCode, 0 );
      //   test.identical( op.ended, true );
      //   test.true( a.fileProvider.fileExists( testAppPath ) );
      //   test.true( !_.strHas( op.output, `Error: Cannot find module` ) );
      //   return null;
      // })
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execute simple js program with normalized path, parent args : [ 'arg' ]`

      let execPath = a.path.nativize( a.path.normalize( testAppPath ) );
      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( execPath ) : 'node ' + _.strQuote( execPath ),
        mode,
        args : [ 'arg' ],
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 1,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      };
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, `[ 'arg' ]` );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        return null;
      } )

    });

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execute simple js program with nativized path, parent args : [ 'arg' ]`

      let o =
      {
        execPath : mode === 'fork' ? _.strQuote( testAppPath ) : 'node ' + _.strQuote( testAppPath ),
        mode,
        args : [ 'arg' ],
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 1,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      };

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, `[ 'arg' ]` );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        return null;
      } )
    })

    return ready;
  }

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let o = _.fileProvider.fileRead({ filePath : _.path.join( __dirname, 'op.json' ), encoding : 'json' });
    o.currentPath = __dirname;
    _.process.startPassingThrough( o );
  }

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

function startMinimalPassingThroughExecPathWithSpace( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program({ routine : testApp, dirPath : 'path with space' });
  let testAppPathParent = a.program( testAppParent );
  // let execPathWithSpace = 'node ' + testAppPath;
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath contains unquoted path with space`

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        outputCollecting : 1,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'pipe'
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        throwingExitCode : 0,
        stdio : 'pipe',
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        let out = JSON.parse( op.output );
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        test.true( !out.err );
        test.true( _.strHas( out.output, `Error: Cannot find module` ) );
        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, args is a string with unquoted path with space`

      let o =
      {
        args : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        outputPiping : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'pipe'
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        throwingExitCode : 0,
        stdio : 'pipe',
      }

      _.process.startMinimal( o2 )

      o2.ready.then( ( op ) =>
      {
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        let out = JSON.parse( op.output );
        if( mode === 'spawn' )
        {
          test.true( !!out.err );
          test.true( a.fileProvider.fileExists( testAppPath ) );
          test.identical( out.err.code, 'ENOENT' );
        }
        else
        {
          test.true( !out.err )
          if( mode === 'fork' )
          test.true( !_.strHas( out.output, `Cannot find module` ) );
          else
          test.true( _.strHas( out.output, `Cannot find module` ) );
        }
        return null;
      })

      return o2.ready;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, args is a string with unquoted path with space and argument`

      let o =
      {
        args : mode === 'fork' ? testAppPath + ' arg' : 'node ' + testAppPath + ' arg',
        mode,
        outputCollecting : 1,
        outputPiping : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'pipe'
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        throwingExitCode : 0,
        stdio : 'pipe',
      }

      _.process.startMinimal( o2 )

      o2.ready.then( ( op ) =>
      {
        let out = JSON.parse( op.output );
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        if( mode === 'spawn' )
        {
          test.true( !!out.err );
          test.true( a.fileProvider.fileExists( testAppPath ) );
          test.identical( out.err.code, 'ENOENT' );
        }
        else
        {
          test.true( !out.err )
          test.true( _.strHas( out.output, `Cannot find module` ) );
        }
        return null;
      })

      return o2.ready;
    })

    return ready;

    /* ORIGINAL */
    // a.ready.then( () =>
    // {
    //   test.case = 'execPath contains unquoted path with space, spawn'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   execPath : execPathWithSpace,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'spawn',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.notIdentical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'execPath contains unquoted path with space, shell'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   execPath : execPathWithSpace,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'shell',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.notIdentical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'execPath contains unquoted path with space, fork'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   execPath : testAppPath,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'spawn',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.notIdentical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'args is a string with unquoted path with space, spawn'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   args : execPathWithSpace,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'spawn',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.finally( ( err, op ) =>
    // {
    //   _.errAttend( err );
    //   test.true( !!err );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( err.message, `ENOENT` ) );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'args is a string with unquoted path with space, shell'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   args : execPathWithSpace,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'shell',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.notIdentical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( op.output, `Cannot find module` ) );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'args is a string with unquoted path with space, fork'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   args : testAppPath,
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'fork',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.identical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   return null;
    // })

    // /* - */

    // a.ready.then( () =>
    // {
    //   test.case = 'args is a string with unquoted path with space and argument, fork'
    //   return null;
    // })

    // _.process.startPassingThrough
    // ({
    //   args : testAppPath + ' arg',
    //   ready : a.ready,
    //   outputCollecting : 1,
    //   outputPiping : 1,
    //   mode : 'fork',
    //   throwingExitCode : 0,
    //   applyingExitCode : 0,
    //   stdio : 'pipe'
    // });

    // a.ready.then( ( op ) =>
    // {
    //   test.notIdentical( op.exitCode, 0 );
    //   test.identical( op.ended, true );
    //   test.true( a.fileProvider.fileExists( testAppPath ) );
    //   test.true( _.strHas( op.output, `Cannot find module` ) );
    //   return null;
    // })

  }


  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let o = _.fileProvider.fileRead({ filePath : _.path.join( __dirname, 'op.json' ), encoding : 'json' });
    o.currentPath = __dirname;
    _.process.startPassingThrough( o )
    .finally( ( err, op ) =>
    {
      console.log( JSON.stringify({ output : op ? op.output : null, err : err ? _.errAttend( err ) : null }) );
      return null;
    } )
  }

  function testApp()
  {
    console.log( process.pid )
    setTimeout( () => {}, context.t1 * 2 ) /* 2000 */
  }
}

//

function startNormalizedExecPath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.path.nativize( a.path.normalize( a.program( testApp ) ) );

  /* */

  let shell = _.process.starter
  ({
    outputCollecting : 1,
    ready : a.ready
  })

  /* */

  shell
  ({
    execPath : testAppPath,
    args : [ 'arg1', 'arg2' ],
    mode : 'fork'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* */

  shell
  ({
    execPath : 'node ' + testAppPath,
    args : [ 'arg1', 'arg2' ],
    mode : 'spawn'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* */

  shell
  ({
    execPath : 'node ' + testAppPath,
    args : [ 'arg1', 'arg2' ],
    mode : 'shell'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* app path in arguments */

  shell
  ({
    args : [ testAppPath, 'arg1', 'arg2' ],
    mode : 'fork'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* */

  shell
  ({
    execPath : 'node',
    args : [ testAppPath, 'arg1', 'arg2' ],
    mode : 'spawn'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* */

  shell
  ({
    execPath : 'node',
    args : [ testAppPath, 'arg1', 'arg2' ],
    mode : 'shell'
  })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.identical( _.strCount( op.output, `[ 'arg1', 'arg2' ]` ), 1 );
    return null;
  })

  /* */

  return a.ready;

  /* - */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

function startMinimalExecPathWithSpace( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( { routine : testApp, dirPath : 'path with space' } );

  let execPathWithSpace = 'node ' + testAppPath;

  /* - */

  a.ready.then( () =>
  {
    test.case = 'execPath contains unquoted path with space, spawn'
    return null;
  })

  _.process.start
  ({
    execPath : execPathWithSpace,
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'spawn',
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'execPath contains unquoted path with space, shell'
    return null;
  })

  _.process.startMinimal
  ({
    execPath : execPathWithSpace,
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'shell',
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'execPath contains unquoted path with space, fork'
    return null;
  })

  _.process.startMinimal
  ({
    execPath : testAppPath,
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'fork',
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( op.output, `Error: Cannot find module` ) );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'args is a string with unquoted path with space, spawn'
    return null;
  })

  _.process.startMinimal
  ({
    args : execPathWithSpace,
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'spawn',
    throwingExitCode : 0
  });

  a.ready.finally( ( err, op ) =>
  {
    _.errAttend( err );
    test.true( !!err );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( err.message, `ENOENT` ) );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'args is a string with unquoted path with space, shell'
    return null;
  })

  _.process.startMinimal
  ({
    args : execPathWithSpace,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'shell',
    ready : a.ready,
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( op.output, `Cannot find module` ) );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'args is a string with unquoted path with space, fork'
    return null;
  })

  _.process.startMinimal
  ({
    args : testAppPath,
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'fork',
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( op.ended, true );
    return null;
  })

  /* - */

  a.ready.then( () =>
  {
    test.case = 'args is a string with unquoted path with space and argument, fork'
    return null;
  })

  _.process.startMinimal
  ({
    args : testAppPath + ' arg',
    ready : a.ready,
    outputCollecting : 1,
    outputPiping : 1,
    mode : 'fork',
    throwingExitCode : 0
  });

  a.ready.then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( op.ended, true );
    test.true( a.fileProvider.fileExists( testAppPath ) );
    test.true( _.strHas( op.output, `Cannot find module` ) );
    return null;
  })

  return a.ready;

  /* - */

  function testApp()
  {
    console.log( process.pid )
    setTimeout( () => {}, context.t1 * 2 ) /* 2000 */
  }
}

//

function startMinimalDifferentTypesOfPaths( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let execPath = a.program({ routine : testApp });
  let execPathWithSpace = a.program({ routine : testApp, dirPath : 'path with space' });
  execPathWithSpace = a.fileProvider.path.normalize( execPathWithSpace );
  let execPathWithSpaceNative = a.fileProvider.path.nativize( execPathWithSpace );

  let tempPath = _.path.tempOpen( _.path.normalize( process.argv[ 0 ] ) );
  let nodeWithSpace = a.path.join( tempPath, 'node.exe' );

  a.fileProvider.softLink( nodeWithSpace, process.argv[ 0 ] );

  /* - */

  a.ready

  .then( () =>
  {
    test.case = 'mode : fork, path with space'
    let o =
    {
      args : execPathWithSpace,
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  .then( () =>
  {
    test.case = 'mode : fork, quoted path with space'
    let o =
    {
      execPath : _.strQuote( execPathWithSpace ),
      mode : 'fork',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  /* zzz for Vova : fix it? */

  // .then( () =>
  // {
  //   test.case = 'mode : fork, double quoted path with space'
  //   let o =
  //   {
  //     execPath : `""${execPathWithSpace}""`,
  //     mode : 'fork',
  //     stdio : 'pipe',
  //     outputCollecting : 1,
  //     outputPiping : 1,
  //     throwingExitCode : 0,
  //     applyingExitCode : 0,
  //   }

  //   _.process.startMinimal( o );

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.true( _.strHas( op.output, execPathWithSpace ) );
  //     return null;
  //   })

  //   return o.conTerminate;

  // })

  /* */

  .then( () =>
  {
    test.case = 'mode : spawn, path to node with space'
    let o =
    {
      args : [ nodeWithSpace, '-v' ],
      mode : 'spawn',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    debugger
    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, process.version ) );
      return null;
    })

    return o.conTerminate;

  })

  .then( () =>
  {
    test.case = 'mode : spawn, path to node with space'
    let o =
    {
      args : [ _.strQuote( nodeWithSpace ), '-v' ],
      mode : 'spawn',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, process.version ) );
      return null;
    })

    return o.conTerminate;

  })

  /* */

  .then( () =>
  {
    test.case = 'mode : spawn, path to node with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ),
      args : [ '-v' ],
      mode : 'spawn',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, process.version ) );
      return null;
    })

    return o.conTerminate;

  })

  /* zzz for Vova : fix it */

  // .then( () =>
  // {
  //   test.case = 'mode : spawn, path to node with space'
  //   let o =
  //   {
  //     execPath : `""${nodeWithSpace}""`,
  //     args : [ '-v' ],
  //     mode : 'spawn',
  //     stdio : 'pipe',
  //     outputCollecting : 1,
  //     outputPiping : 1,
  //     throwingExitCode : 0,
  //     applyingExitCode : 0,
  //   }

  //   _.process.startMinimal( o );

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.true( _.strHas( op.output, process.version ) );
  //     return null;
  //   })

  //   return o.conTerminate;

  // })

  /* */

  .then( () =>
  {
    test.case = 'mode : spawn, path to node with space, path to program with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ) + ' ' + _.strQuote( execPathWithSpaceNative ),
      mode : 'spawn',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  /* */

  .then( () =>
  {
    test.case = 'mode : spawn, path to node with space, path to program with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ),
      args : [ execPathWithSpaceNative ],
      mode : 'spawn',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  /* zzz for Vova : fix it? */

  // .then( () =>
  // {
  //   test.case = 'mode : shell, path to node with space'
  //   let o =
  //   {
  //     args : [ _.strQuote( nodeWithSpace ), '-v' ],
  //     mode : 'shell',
  //     stdio : 'pipe',
  //     outputCollecting : 1,
  //     outputPiping : 1,
  //     throwingExitCode : 0,
  //     applyingExitCode : 0,
  //   }

  //   _.process.startMinimal( o );

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.true( _.strHas( op.output, process.version ) );
  //     return null;
  //   })

  //   return o.conTerminate;

  // })

  /* */

  .then( () =>
  {
    test.case = 'mode : shell, path to node with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ),
      args : [ '-v' ],
      mode : 'shell',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, process.version ) );
      return null;
    })

    return o.conTerminate;

  })

  /* */

  .then( () =>
  {
    test.case = 'mode : shell, path to node with space, program path with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ),
      args : [ execPathWithSpaceNative ],
      mode : 'shell',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  /* */

  .then( () =>
  {
    test.case = 'mode : shell, path to node with space, program path with space'
    let o =
    {
      execPath : _.strQuote( nodeWithSpace ) + ' ' + _.strQuote( execPathWithSpaceNative ),
      mode : 'shell',
      stdio : 'pipe',
      outputCollecting : 1,
      outputPiping : 1,
      throwingExitCode : 0,
      applyingExitCode : 0,
    }

    _.process.startMinimal( o );

    o.conTerminate.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, execPathWithSpace ) );
      return null;
    })

    return o.conTerminate;

  })

  /* - */

  a.ready.tap( () =>
  {
    _.path.tempClose( tempPath );
  })


  return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    console.log( _.path.normalize( __filename ) );
  }
}

//


function startNjsPassingThroughExecPathWithSpace( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPathParent = a.program( testAppParent );
  let testAppPath = a.program({ routine : testApp, dirPath : 'path with space' });
  let execPathWithSpace = testAppPath;

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath contains unquoted path with space`;

      let o =
      {
        execPath : mode === 'fork' ? execPathWithSpace : 'node ' + execPathWithSpace,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 1,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        throwingExitCode : 0,
        stdio : 'pipe',
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        test.true( _.strHas( op.output, `Error: Cannot find module` ) );
        return null;
      })

      /* ORIGINAL */
      // test.case = 'execPath contains unquoted path with space'
      // return _.process.startNjsPassingThrough
      // ({
      //   execPath : execPathWithSpace,
      //   stdio : 'pipe',
      //   outputCollecting : 1,
      //   outputPiping : 1,
      //   throwingExitCode : 0,
      //   applyingExitCode : 0,
      // })
      // .then( ( op ) =>
      // {
      //   test.notIdentical( op.exitCode, 0 );
      //   test.identical( op.ended, true );
      //   test.true( a.fileProvider.fileExists( testAppPath ) );
      //   test.true( _.strHas( op.output, `Error: Cannot find module` ) );
      //   return null;
      // })
    })

    /* - */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, args: string that contains unquoted path with space`;

      let o =
      {
        execPath : mode === 'fork' ? null : 'node',
        args : execPathWithSpace,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        stdio : 'pipe',
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        let out = JSON.parse( op.output );
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        if( mode === 'shell' )
        test.true( _.strHas( out.output, '[]' ) )
        else
        test.equivalent( out.output, '[]\n' + out.pid.toString() )
        return null;
      })

      /* ORIGINAL */
      // test.case = 'args: string that contains unquoted path with space'

      // return _.process.startNjsPassingThrough
      // ({
      //   args : execPathWithSpace,
      //   stdio : 'pipe',
      //   outputCollecting : 1,
      //   outputPiping : 1,
      //   throwingExitCode : 0,
      //   applyingExitCode : 0,
      // })
      // .then( ( op ) =>
      // {
      //   test.identical( op.exitCode, 0 );
      //   test.identical( op.ended, true );
      //   test.true( a.fileProvider.fileExists( testAppPath ) );
      //   test.true( _.strHas( op.output, op.pnd.pid.toString() ) );
      //   return null;
      // })
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}, args: string that contains unquoted path with space and 'arg'`;

      let o =
      {
        execPath : mode === 'fork' ? null : 'node',
        args : [ execPathWithSpace, 'arg' ],
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
        outputPiping : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        applyingExitCode : 0,
      }

      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' })

      let o2 =
      {
        execPath : 'node ' + testAppPathParent,
        mode : 'spawn',
        outputCollecting : 1,
        stdio : 'pipe',
      }

      return _.process.startMinimal( o2 )
      .then( ( op ) =>
      {
        let out = JSON.parse( op.output );
        test.identical( op.ended, true );
        test.true( a.fileProvider.fileExists( testAppPath ) );
        if( mode === 'shell' )
        test.true( _.strHas( out.output, `[ 'arg' ]` ) )
        else
        test.equivalent( out.output, `[ 'arg' ]\n` + out.pid.toString() )
        return null;
      })
    })

    return ready;
  }


  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let o = _.fileProvider.fileRead({ filePath : _.path.join( __dirname, 'op.json' ), encoding : 'json' });
    o.currentPath = __dirname;
    _.process.startPassingThrough( o )
    .then( ( op ) =>
    {
      console.log( JSON.stringify({ pid : op.pnd.pid, output : op.output }) )
      return null;
    } );
  }

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
    console.log( process.pid )
    setTimeout( () => {}, context.t1 * 2 ) /* 2000 */
  }
}

//

// --
// procedures / chronology / structural
// --

function startProcedureTrivial( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let start = _.process.starter
  ({
    currentPath : a.routinePath,
    outputPiping : 1,
    outputCollecting : 1,
  });

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`
      var o = { execPath : `${mode === 'fork' ? '' : 'node ' }` + testAppPath, mode }
      var con = start( o );
      var procedure = _.procedure.find( 'PID:' + o.pnd.pid );
      test.identical( procedure.length, 1 );
      test.identical( procedure[ 0 ].isAlive(), true );
      test.identical( o.procedure, procedure[ 0 ] );
      test.identical( procedure[ 0 ].object(), o.pnd );
      return con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( procedure[ 0 ].isAlive(), false );
        test.identical( o.procedure, procedure[ 0 ] );
        test.identical( procedure[ 0 ].object(), o.pnd );
        test.true( _.strHas( o.procedure._sourcePath, 'Execution.s' ) ); debugger;
        return null;
      })
    })

    return ready;
  }


  /* ORIGINAL */
  // a.ready

  // /* */

  // .then( () =>
  // {

  //   var o = { execPath : 'node ' + testAppPath, mode : 'shell' }
  //   var con = start( o );
  //   var procedure = _.procedure.find( 'PID:' + o.pnd.pid );
  //   test.identical( procedure.length, 1 );
  //   test.identical( procedure[ 0 ].isAlive(), true );
  //   test.identical( o.procedure, procedure[ 0 ] );
  //   test.identical( procedure[ 0 ].object(), o.pnd );
  //   return con.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( procedure[ 0 ].isAlive(), false );
  //     test.identical( o.procedure, procedure[ 0 ] );
  //     test.identical( procedure[ 0 ].object(), o.pnd );
  //     test.true( _.strHas( o.procedure._sourcePath, 'Execution.s' ) ); debugger;
  //     return null;
  //   })
  // })

  // /* */

  // .then( () =>
  // {

  //   var o = { execPath : testAppPath, mode : 'fork' }
  //   var con = start( o );
  //   var procedure = _.procedure.find( 'PID:' + o.pnd.pid );
  //   test.identical( procedure.length, 1 );
  //   test.identical( procedure[ 0 ].isAlive(), true );
  //   test.identical( o.procedure, procedure[ 0 ] );
  //   test.identical( procedure[ 0 ].object(), o.pnd );
  //   return con.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( procedure[ 0 ].isAlive(), false );
  //     test.identical( o.procedure, procedure[ 0 ] );
  //     test.identical( procedure[ 0 ].object(), o.pnd );
  //     test.true( _.strHas( o.procedure._sourcePath, 'Execution.s' ) );
  //     return null;
  //   })
  // })

  // /* */

  // .then( () =>
  // {

  //   var o = { execPath : 'node ' + testAppPath, mode : 'spawn' }
  //   var con = start( o );
  //   var procedure = _.procedure.find( 'PID:' + o.pnd.pid );
  //   test.identical( procedure.length, 1 );
  //   test.identical( procedure[ 0 ].isAlive(), true );
  //   test.identical( o.procedure, procedure[ 0 ] );
  //   test.identical( procedure[ 0 ].object(), o.pnd );
  //   return con.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( procedure[ 0 ].isAlive(), false );
  //     test.identical( o.procedure, procedure[ 0 ] );
  //     test.identical( procedure[ 0 ].object(), o.pnd );
  //     test.true( _.strHas( o.procedure._sourcePath, 'Execution.s' ) );
  //     return null;
  //   })
  // })

  // /* */


  // return a.ready;

  /* - */

  function testApp()
  {
    console.log( process.pid )
    setTimeout( () => {}, context.t1 * 2 ) /* 2000 */
  }
}

startProcedureTrivial.timeOut = 1e5; /* Locally : 9.367s */
startProcedureTrivial.description =
`
  Start routine creates procedure for new child process, start it and terminates when process closes
`

//

function startProcedureExists( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );

  let start = _.process.starter
  ({
    currentPath : a.routinePath,
    outputPiping : 1,
    outputCollecting : 1,
  });

  _.process.watcherEnable();

  let modes = [ 'spawn', 'shell', 'fork' ];

  modes.forEach( mode =>
  {
    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  })

  a.ready.then( () => _.process.watcherDisable() );

  return a.ready

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      var o = { execPath : 'node ' + testAppPath, mode }
      if( mode === 'fork' )
      o.execPath = testAppPath;
      var con = start( o );
      var procedure = _.procedure.find( 'PID:' + o.pnd.pid );
      test.identical( procedure.length, 1 );
      test.identical( procedure[ 0 ].isAlive(), true );
      test.identical( o.procedure, procedure[ 0 ] );
      test.identical( procedure[ 0 ].object(), o.pnd );
      test.identical( o.procedure, procedure[ 0 ] );
      return con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( procedure[ 0 ].isAlive(), false );
        test.identical( o.procedure, procedure[ 0 ] );
        test.identical( procedure[ 0 ].object(), o.pnd );
        test.identical( o.procedure, procedure[ 0 ] );
        debugger
        test.true( _.strHas( o.procedure._sourcePath, 'Execution.s' ) );
        return null;
      })
    })

    return ready;
  }

  /* */


  function program1()
  {
    console.log( process.pid )
    setTimeout( () => {}, context.t1 * 2 ) /* 2000 */
  }

}

startProcedureExists.description =
`
  Start routine does not create procedure for new child process if it was already created by process watcher
`

//

function startSingleProcedureStack( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /*  */

  function run( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:implicit`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'case1' ), 1 );
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:true`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : true,
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'case1' ), 1 );
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:0`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : 0,
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'case1' ), 1 );
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:-1`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : -1,
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'start' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'start' ), 1 );
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:false`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : false,
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( o.procedure._stack, '' );
      test.identical( o.procedure._sourcePath, '' );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( o.procedure._stack, '' );
        test.identical( o.procedure._sourcePath, '' );
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:str`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : 'abc',
        mode,
        sync,
        deasync,
      }

      _.process.start( o );

      test.identical( o.procedure._stack, 'abc' );
      test.identical( o.procedure._sourcePath, 'abc' );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( o.procedure._stack, 'abc' );
        test.identical( o.procedure._sourcePath, 'abc' );
        return null;
      })

      return o.ready;
    })

    /* */

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    console.log( JSON.stringify( data ) );
  }

}

startSingleProcedureStack.rapidity = -1;
startSingleProcedureStack.timeOut = 5e5;
startSingleProcedureStack.description =
`
  - option stack used to get stack
  - stack may be defined relatively
  - stack may be switched off
`

//

function startMultipleProcedureStack( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /*  */

  function run( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:implicit`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( _.strCount( op2.procedure._stack, 'case1' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'Execution.test.s' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'case1' ), 1 );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:true`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : true,
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( _.strCount( op2.procedure._stack, 'case1' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'Execution.test.s' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'case1' ), 1 );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:0`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : 0,
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'Execution.test.s' ), 1 );
        test.identical( _.strCount( o.procedure._sourcePath, 'case1' ), 1 );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( _.strCount( op2.procedure._stack, 'case1' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'Execution.test.s' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'case1' ), 1 );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:-1`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : -1,
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
      test.identical( _.strCount( o.procedure._sourcePath, 'start' ), 1 );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( _.strCount( o.procedure._stack, 'case1' ), 1 );
        test.identical( _.strCount( op.procedure._sourcePath, 'start' ), 1 );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( _.strCount( op2.procedure._stack, 'case1' ), 1 );
          test.identical( _.strCount( op2.procedure._sourcePath, 'start' ), 1 );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:false`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : false,
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( o.procedure._stack, '' );
      test.identical( o.procedure._sourcePath, '' );
      test.identical( o.procedure._sourcePath, '' );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( o.procedure._stack, '' );
        test.identical( o.procedure._sourcePath, '' );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( op2.procedure._stack, '' );
          test.identical( op2.procedure._sourcePath, '' );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( function case1()
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode} stack:str`;
      let t1 = _.time.now();
      let o =
      {
        execPath : mode !== `fork` ? [ `node ${programPath} id:1`, `node ${programPath} id:2` ] : [ `${programPath} id:1`, `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        stack : 'abc',
        mode,
        sync,
        deasync,
      }

      _.process.startMultiple( o );

      if( sync || deasync )
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
      }
      else
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, null );
        test.identical( o.ended, false );
        test.identical( o.state, 'starting' );
      }

      test.identical( o.procedure._stack, 'abc' );
      test.identical( o.procedure._sourcePath, 'abc' );
      test.identical( o.procedure._sourcePath, 'abc' );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );
        test.identical( o.exitReason, 'normal' );
        test.identical( o.ended, true );
        test.identical( o.state, 'terminated' );
        test.identical( o.procedure._stack, 'abc' );
        test.identical( o.procedure._sourcePath, 'abc' );

        o.sessions.forEach( ( op2 ) =>
        {
          test.identical( op2.procedure._stack, 'abc' );
          test.identical( op2.procedure._sourcePath, 'abc' );
          test.true( o.procedure !== op2.procedure );
        });

        return null;
      })

      return o.ready;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    console.log( JSON.stringify( data ) );
  }

}

startMultipleProcedureStack.rapidity = -1;
startMultipleProcedureStack.timeOut = 500000;

//

function startMinimalOnTerminateSeveralCallbacksChronology( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, parent disconnects detached child process and exits, child contiues to work`
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        mode,
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
        currentPath : a.routinePath,
        detaching : 0,
        ipc : mode === 'shell' ? 0 : 1,
      }
      let con = _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate.1' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.state, 'terminated' );
        return null;
      })

      o.conTerminate.then( () =>
      {
        track.push( 'conTerminate.2' );
        test.identical( o.exitCode, 0 );
        test.identical( o.state, 'terminated' );
        return _.time.out( context.t1 * 6 ); /* 1000 + context.t2 */
      })

      o.conTerminate.then( () =>
      {
        track.push( 'conTerminate.3' );
        test.identical( o.exitCode, 0 );
        test.identical( o.state, 'terminated' );
        return null;
      })

      track.push( 'end' );
      return con;
    })

    .tap( () =>
    {
      track.push( 'ready' );
    })

    /*  */

    return _.time.out( context.t1 * 11, () => /* 1000 + context.t2 + context.t2 */
    {
      test.identical( track, [ 'end', 'conTerminate.1', 'conTerminate.2', 'ready', 'conTerminate.3' ] );
    });
  }

  /* - */

  function program1()
  {
    console.log( 'program1:begin' );
    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 ); /* 1000 */
  }

}

startMinimalOnTerminateSeveralCallbacksChronology.timeOut = 4e5; /* Locally : 36.424s */
startMinimalOnTerminateSeveralCallbacksChronology.description =
`
- second onTerminal callbacks called after ready callback
`

//

function startMinimalChronology( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let track;
  let niteration = 0;

  var modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /* */

  function run( sync, deasync, mode )
  {
    test.case = `sync:${sync} deasync:${deasync} mode:${mode}`;

    if( sync && mode === 'fork' )
    return null;

    niteration += 1;
    let ptcounter = _.Procedure.Counter;
    let pacounter = _.Procedure.FindAlive().length;
    track = [];

    var o =
    {
      execPath : mode !== 'fork' ? 'node' : null,
      args : [ testAppPath ],
      mode,
      sync,
      deasync,
      ready : new _.Consequence().take( null ),
      conStart : new _.Consequence(),
      conDisconnect : new _.Consequence(),
      conTerminate : new _.Consequence(),
    }

    test.identical( _.Procedure.Counter - ptcounter, 0 );
    ptcounter = _.Procedure.Counter;
    test.identical( _.Procedure.FindAlive().length - pacounter, 0 );
    pacounter = _.Procedure.FindAlive().length;

    o.conStart.tap( ( err, op ) =>
    {
      track.push( 'conStart' );

      test.identical( err, undefined );
      test.identical( op, o );

      test.identical( o.ready.argumentsCount(), 0 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), 0 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 0 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 0 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 1 );
      test.identical( o.ended, false );
      test.identical( o.state, 'started' );
      test.identical( o.error, null );
      test.identical( o.exitCode, null );
      test.identical( o.exitSignal, null );
      test.identical( o.pnd.exitCode, ( sync && !deasync ) ? undefined : null );
      test.identical( o.pnd.signalCode, ( sync && !deasync ) ? undefined : null );
      test.identical( _.Procedure.Counter - ptcounter, ( sync && !deasync ) ? 3 : 2 );
      ptcounter = _.Procedure.Counter;
      test.identical( _.Procedure.FindAlive().length - pacounter, ( sync && !deasync ) ? 1 : 2 );
      pacounter = _.Procedure.FindAlive().length;
    });

    test.identical( _.Procedure.Counter - ptcounter, 1 );
    ptcounter = _.Procedure.Counter;
    test.identical( _.Procedure.FindAlive().length - pacounter, 1 );
    pacounter = _.Procedure.FindAlive().length;

    o.conTerminate.tap( ( err, op ) =>
    {
      track.push( 'conTerminate' );

      test.identical( err, undefined );
      test.identical( op, o );

      test.identical( o.ready.argumentsCount(), 0 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), ( sync && !deasync ) ? 0 : 1 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 0 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 1 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 0 );
      test.identical( o.ended, true );
      test.identical( o.state, 'terminated' );
      test.identical( o.error, null );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      test.identical( o.pnd.exitCode, 0 );
      test.identical( o.pnd.signalCode, null );
      test.identical( _.Procedure.Counter - ptcounter, ( sync && !deasync ) ? 0 : 1 );
      ptcounter = _.Procedure.Counter;
      if( sync || deasync )
      test.identical( _.Procedure.FindAlive().length - pacounter, -2 );
      else
      test.identical( _.Procedure.FindAlive().length - pacounter, niteration > 1 ? -1 : 0 );
      pacounter = _.Procedure.FindAlive().length;
      /*
      2 extra procedures dies here on non-first iteration
        2 procedures of _.time.out()
      */
    })

    let result = _.time.out( context.t1 * 6, () => /* 1000 + context.t2 */
    {
      test.identical( track, [ 'conStart', 'conTerminate', 'ready' ] );

      test.identical( o.ready.argumentsCount(), 1 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), 0 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 1 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 1 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 0 );
      test.identical( o.ended, true );
      test.identical( o.state, 'terminated' );
      test.identical( o.error, null );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      test.identical( o.pnd.exitCode, 0 );
      test.identical( o.pnd.signalCode, null );
      test.identical( _.Procedure.Counter - ptcounter, 0 );
      ptcounter = _.Procedure.Counter;
      if( sync || deasync )
      test.identical( _.Procedure.FindAlive().length - pacounter, niteration > 1 ? -2 : -1 );
      else
      test.identical( _.Procedure.FindAlive().length - pacounter, -1 );
      pacounter = _.Procedure.FindAlive().length;
      /*
      2 extra procedures dies here on non-first iteration
        2 procedures of _.time.out()
      */
    });

    test.identical( _.Procedure.Counter - ptcounter, 3 );
    ptcounter = _.Procedure.Counter;
    test.identical( _.Procedure.FindAlive().length - pacounter, 3 );
    pacounter = _.Procedure.FindAlive().length;

    let returned = _.process.startMinimal( o );

    if( sync )
    test.true( returned === o );
    else
    test.true( returned === o.ready );
    test.true( o.conStart !== o.ready );
    test.true( o.conDisconnect !== o.ready );
    test.true( o.conTerminate !== o.ready );

    test.identical( o.ready.argumentsCount(), ( sync || deasync ) ? 1 : 0 );
    test.identical( o.ready.errorsCount(), 0 );
    test.identical( o.ready.competitorsCount(), 0 );
    test.identical( o.conStart.argumentsCount(), 1 );
    test.identical( o.conStart.errorsCount(), 0 );
    test.identical( o.conStart.competitorsCount(), 0 );
    test.identical( o.conDisconnect.argumentsCount(), 0 );
    test.identical( o.conDisconnect.errorsCount(), ( sync || deasync ) ? 1 : 0 );
    test.identical( o.conDisconnect.competitorsCount(), 0 );
    test.identical( o.conTerminate.argumentsCount(), ( sync || deasync ) ? 1 : 0 );
    test.identical( o.conTerminate.errorsCount(), 0 );
    test.identical( o.conTerminate.competitorsCount(), ( sync || deasync ) ? 0 : 1 );
    test.identical( o.ended, ( sync || deasync ) ? true : false );
    test.identical( o.state, ( sync || deasync ) ? 'terminated' : 'started' );
    test.identical( o.error, null );
    test.identical( o.exitCode, ( sync || deasync ) ? 0 : null );
    test.identical( o.exitSignal, null );
    test.identical( o.pnd.exitCode, ( sync || deasync ) ? 0 : null );
    test.identical( o.pnd.signalCode, null );
    test.identical( _.Procedure.Counter - ptcounter, 0 );
    ptcounter = _.Procedure.Counter;
    test.identical( _.Procedure.FindAlive().length - pacounter, ( sync && !deasync ) ? -1 : -2 );
    pacounter = _.Procedure.FindAlive().length;

    o.ready.tap( ( err, op ) =>
    {
      track.push( 'ready' );

      test.identical( err, undefined );
      test.identical( op, o );

      test.identical( o.ready.argumentsCount(), 1 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), 0 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 1 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 1 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 0 );
      test.identical( o.ended, true );
      test.identical( o.state, 'terminated' );
      test.identical( o.error, null );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      test.identical( o.pnd.exitCode, 0 );
      test.identical( o.pnd.signalCode, null );
      test.identical( _.Procedure.Counter - ptcounter, ( sync || deasync ) ? 1 : 0 );
      ptcounter = _.Procedure.Counter;
      test.identical( _.Procedure.FindAlive().length - pacounter, ( sync || deasync ) ? 1 : -1 );
      pacounter = _.Procedure.FindAlive().length;
      return null;
    })

    return result;
  }

  /* - */

  function testApp()
  {
    setTimeout( () => {}, context.t1 ); /* 1000 */
  }

}

startMinimalChronology.rapidity = -1;
startMinimalChronology.timeOut = 5e5;
startMinimalChronology.description =
`
  - conTerminate goes before ready
  - conStart goes before conTerminate
  - procedures generated
  - no extra procedures generated
`

function startMultipleState( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let testAppErrorPath = a.program( testAppError );
  var modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );
    /*
    Possible states: `initial`, `starting`, `started`, `terminating`, `terminated`, `disconnected`
    Possible to check : `starting`, `started`, `terminating`, `terminated`
    */
    let states;

    ready.then( ( op ) =>
    {
      test.case = `mode:${mode}, concurrent : 0, normal run`;
      states = [];

      let options =
      {
        execPath : mode === 'fork' ? [ testAppPath, testAppPath ] : [ 'node ' + testAppPath, 'node ' + testAppPath ],
        mode,
        concurrent : 0,
        outputCollecting : 1
      }

      let returned = _.process.startMultiple( options );

      options.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.identical( op.output, '' );
        states.push( op.state );
        return null;
      } )

      options.conTerminate.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.equivalent( op.output, 'Log\nLog' );
        states.push( op.state );
        return null;
      } )

      options.ready.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, 0 )
        test.identical( op.ended, true )
        test.equivalent( op.output, 'Log\nLog' );
        states.push( op.state );
        test.identical( states, [ 'starting', 'terminating', 'terminated' ] )
        return null;
      } )

      return returned;

    } )

    /* */

    ready.then( ( op ) =>
    {
      test.case = `mode:${mode}, concurrent : 1, normal run`;
      states = [];

      let options =
      {
        execPath : mode === 'fork' ? [ testAppPath, testAppPath ] : [ 'node ' + testAppPath, 'node ' + testAppPath ],
        mode,
        concurrent : 1,
        outputCollecting : 1
      }

      let returned = _.process.startMultiple( options );

      options.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.identical( op.output, '' );
        states.push( op.state );
        return null;
      } )

      options.conTerminate.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.equivalent( op.output, 'Log\nLog' );
        states.push( op.state );
        return null;
      } )

      options.ready.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, 0 )
        test.identical( op.ended, true )
        test.equivalent( op.output, 'Log\nLog' );
        states.push( op.state );
        test.identical( states, [ 'started', 'terminating', 'terminated' ] )
        return null;
      } )

      return returned;

    } )

    /* */

    ready.then( ( op ) =>
    {
      test.case = `mode:${mode}, concurrent : 0, error`;
      states = [];

      let options =
      {
        execPath : mode === 'fork' ? [ testAppErrorPath, testAppErrorPath ] : [ 'node ' + testAppErrorPath, 'node ' + testAppErrorPath ],
        mode,
        concurrent : 0,
        throwingExitCode : 0,
        outputCollecting : 1
      }

      let returned = _.process.startMultiple( options );

      options.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.identical( op.output, '' );
        states.push( op.state );
        return null;
      } )

      options.conTerminate.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.true( _.strHas( op.output, 'randomText is not defined' ) );
        states.push( op.state );
        return null;
      } )

      options.ready.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.notIdentical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'randomText is not defined' ) );
        states.push( op.state );
        test.identical( states, [ 'starting', 'terminating', 'terminated' ] );
        return null;
      } )

      return returned;
    } )

    /* */

    ready.then( ( op ) =>
    {
      test.case = `mode:${mode}, concurrent : 1, error`;
      states = [];

      let options =
      {
        execPath : mode === 'fork' ? [ testAppErrorPath, testAppErrorPath ] : [ 'node ' + testAppErrorPath, 'node ' + testAppErrorPath ],
        mode,
        concurrent : 1,
        throwingExitCode : 0,
        outputCollecting : 1
      }

      let returned = _.process.startMultiple( options );

      options.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.identical( op.output, '' );
        states.push( op.state );
        return null;
      } )

      options.conTerminate.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.true( _.strHas( op.output, 'randomText is not defined' ) );
        states.push( op.state );
        return null;
      } )

      options.ready.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.notIdentical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'randomText is not defined' ) );
        states.push( op.state );
        test.identical( states, [ 'started', 'terminating', 'terminated' ] );
        return null;
      } )

      return returned;
    } )

    return ready;
  }

  function testApp()
  {
    console.log( 'Log' );
  }

  function testAppError()
  {
    randomText
  }
}

// --
// delay
// --

function startSingleReadyDelay( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  // let modes = [ 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => single( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => single( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => single( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => single( 1, 1, mode ) ) );
  return a.ready;

  /*  */

  function single( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    ready.then( () =>
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode}`;
      let t1 = _.time.now();
      let ready = new _.Consequence().take( null ).delay( context.t2 );
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath} id:1` : `${programPath} id:1`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        mode,
        sync,
        deasync,
        ready,
      }

      let returned = _.process.startSingle( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let parsed = JSON.parse( op.output );
        let diff = parsed.time - t1;
        console.log( diff );
        test.ge( diff, context.t2 );
        return null;
      })

      return returned;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    console.log( JSON.stringify( data ) );
  }

}

startSingleReadyDelay.rapidity = -1;
startSingleReadyDelay.timeOut = 5e5;
startSingleReadyDelay.description =
`
  - delay in consequence ready delay starting of the process
`

//

function startMultipleReadyDelay( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );
  return a.ready;

  /* - */

  function run( op )
  {
    let ready = new _.Consequence().take( null )

    if( op.sync && !op.deasync && op.mode === 'fork' )
    return null;

    /* */

    ready.then( () =>
    {
      test.case = `sync:${op.sync} deasync:${op.deasync} concurrent:0 mode:${op.mode}`;
      let t1 = _.time.now();
      let ready2 = new _.Consequence().take( null ).delay( context.t1*4 );
      let o =
      {
        execPath : [ ( op.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:1`, ( op.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputPiping : 1,
        outputCollecting : 1,
        outputAdditive : 1,
        sync : op.sync,
        deasync : op.deasync,
        concurrent : 0,
        mode : op.mode,
        ready : ready2,
      }

      let returned = _.process.startMultiple( o );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        op.sessions.forEach( ( op2, counter ) =>
        {
          test.identical( op2.exitCode, 0 );
          test.identical( op2.exitSignal, null );
          test.identical( op2.exitReason, 'normal' );
          test.identical( op2.ended, true );
          let parsed = a.fileProvider.fileRead({ filePath : a.abs( `${counter+1}.json` ), encoding : 'json' });
          let diff = parsed.time - t1;
          console.log( diff );
          test.ge( diff, context.t1*4 );
          test.identical( parsed.id, counter+1 );
        });
        return null;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `sync:${op.sync} deasync:${op.deasync} concurrent:1 mode:${op.mode}`;

      if( op.sync && !op.deasync )
      return null;

      let t1 = _.time.now();
      let ready2 = new _.Consequence().take( null ).delay( context.t1*4 );
      let o =
      {
        execPath : [ ( op.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:1`, ( op.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputPiping : 1,
        outputCollecting : 1,
        outputAdditive : 1,
        sync : op.sync,
        deasync : op.deasync,
        concurrent : 1,
        mode : op.mode,
        ready : ready2,
      }

      let returned = _.process.startMultiple( o );

      o.ready.then( ( op ) =>
      {
        test.true( op === o );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        op.sessions.forEach( ( op2, counter ) =>
        {
          test.identical( op2.exitCode, 0 );
          test.identical( op2.exitSignal, null );
          test.identical( op2.exitReason, 'normal' );
          test.identical( op2.ended, true );
          let parsed = a.fileProvider.fileRead({ filePath : a.abs( `${counter+1}.json` ), encoding : 'json' });
          let diff = parsed.time - t1;
          console.log( diff );
          test.ge( diff, context.t1*4 );
          test.identical( parsed.id, counter+1 );
        });
        return null;
      })

      return returned;
    })

    /* */

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    _.fileProvider.fileWrite({ filePath : _.path.join(__dirname, `${args.map.id}.json` ), data, encoding : 'json' });
    console.log( `${args.map.id}::begin` )
    setTimeout( () => console.log( `${args.map.id}::end` ), context.t1 );
  }

}

startMultipleReadyDelay.rapidity = -1;
startMultipleReadyDelay.timeOut = 5e5;
startMultipleReadyDelay.description =
`
  - delay in consequence ready delay starting of 2 processes
  - concurrent starting does not cause problems
`

//

function startMinimalOptionWhenDelay( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  // let modes = [ 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /*  */

  function run( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    ready.then( () =>
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode}`;
      let t1 = _.time.now();
      let when = { delay : context.t2 };
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        when : when,
        sync,
        deasync,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let parsed = JSON.parse( op.output );
        let diff = parsed.time - t1;
        console.log( diff );
        test.ge( diff, when.delay );
        return null;
      })

      return returned;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    let data = { time : _.time.now() };
    console.log( JSON.stringify( data ) );
  }

}

startMinimalOptionWhenDelay.timeOut = 5e5;
startMinimalOptionWhenDelay.rapidity = -1;

//

function startMinimalOptionWhenTime( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /* */

  function run( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    ready.then( () =>
    {
      test.case = `sync:${sync} deasync:${deasync} mode:${mode}`;

      let t1 = _.time.now();
      let delay = context.t2; /* 5000 */
      let when = { time : _.time.now() + delay };
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        when,
        sync,
        deasync,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let parsed = JSON.parse( op.output );
        let diff = parsed.time - t1;
        test.ge( diff, delay );
        return null;
      })

      return returned;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );

    let data = { time : _.time.now() };
    console.log( JSON.stringify( data ) );
  }
}

startMinimalOptionWhenTime.timeOut = 5e5;
startMinimalOptionWhenTime.rapidity = -1;

//

function startMinimalOptionTimeOut( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath1 = a.program({ routine : program1 });
  let programPath2 = a.program({ routine : program2 });
  let programPath3 = a.program({ routine : program3 });
  let programPath4 = a.program({ routine : program4 });
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null )

    ready.then( () =>
    {
      test.case = `mode:${mode}, child process sessions for some time`;

      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : `node program1.js`,
        mode,
        currentPath : a.routinePath,
        timeOut : context.t1*3,
      }

      _.process.startMinimal( o );

      return test.shouldThrowErrorAsync( o.conTerminate )
      .then( () =>
      {
        /* Child process on Windows terminates with 'SIGTERM' because process was terminated using process descriptor*/
        test.identical( o.exitCode, null );
        test.identical( o.ended, true );
        test.identical( o.exitSignal, 'SIGTERM' );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, child process ignores SIGTERM`;

      let o =
      {
        execPath : mode === 'fork' ? 'program2.js' : `node program2.js`,
        mode,
        currentPath : a.routinePath,
        timeOut : context.t1*3,
      }

      _.process.startMinimal( o );

      return test.shouldThrowErrorAsync( o.conTerminate )
      .then( () =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGTERM' );
        }
        else if( process.platform === 'darwin' )
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGKILL' );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          if( mode === 'shell' )
          test.identical( o.exitSignal, 'SIGTERM' );
          else
          test.identical( o.exitSignal, 'SIGKILL' );
        }
        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, process has single child that sessions normally, process waits until child will exit`;

      let o =
      {
        execPath : mode === 'fork' ? 'program3.js' : `node program3.js`,
        args : 'program1.js',
        mode,
        currentPath : a.routinePath,
        timeOut : context.t1*3,
        outputPiping : 1,
        outputCollecting : 1
      }

      _.process.startMinimal( o );

      return test.shouldThrowErrorAsync( o.conTerminate )
      .then( () =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGTERM' );
          test.true( !_.strHas( o.output, 'Process was killed by exit signal SIGTERM' ) );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGTERM' );
          test.true( _.strHas( o.output, 'Process was killed by exit signal SIGTERM' ) );
        }
        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, parent and child ignore SIGTERM`;

      let o =
      {
        execPath : mode === 'fork' ? 'program4.js' : `node program4.js`,
        args : 'program2.js',
        mode,
        currentPath : a.routinePath,
        timeOut : context.t1*3,
        outputPiping : 1,
        outputCollecting : 1
      }

      _.process.startMinimal( o );

      return test.shouldThrowErrorAsync( o.conTerminate )
      .then( () =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGTERM' );
        }
        else if( process.platform === 'darwin' )
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          test.identical( o.exitSignal, 'SIGKILL' );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.ended, true );
          if( mode === 'shell' )
          test.identical( o.exitSignal, 'SIGTERM' );
          else
          test.identical( o.exitSignal, 'SIGKILL' );
        }

        return null;
      })
    })

    return ready;
  }

  /* */

  function program1()
  {
    console.log( 'program1::start' )
    setTimeout( () =>
    {
      console.log( 'program1::end' )
    }, context.t1*6 )
  }

  /* */

  function program2()
  {
    console.log( 'program2::start', process.pid )
    setTimeout( () =>
    {
      console.log( 'program2::end' )
    }, context.t1*12 )

    process.on( 'SIGTERM', () =>
    {
      console.log( 'program2: SIGTERM is ignored')
    })
  }

  /* */

  function program3()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    process.removeAllListeners( 'SIGHUP' );
    process.removeAllListeners( 'SIGINT' );
    process.removeAllListeners( 'SIGTERM' );

    let o =
    {
      execPath : 'node',
      args : process.argv.slice( 2 ),
      mode : 'spawn',
      currentPath : __dirname,
      stdio : 'pipe',
      outputPiping : 1,
    }
    _.process.startMinimal( o );

    /* ignores SIGTERM until child process will be terminated, then emits SIGTERM by itself */
    process.on( 'SIGTERM', () =>
    {
      o.conTerminate.catch( ( err ) =>
      {
        _.errLogOnce( err );
        process.removeAllListeners( 'SIGHUP' );
        process.removeAllListeners( 'SIGINT' );
        process.removeAllListeners( 'SIGTERM' );
        process.kill( process.pid, 'SIGTERM' );
        return null;
      })
    })
  }

  /* */

  function program4()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    process.removeAllListeners( 'SIGHUP' );
    process.removeAllListeners( 'SIGINT' );
    process.removeAllListeners( 'SIGTERM' );

    let o =
    {
      execPath : 'node',
      args : process.argv.slice( 2 ),
      mode : 'spawn',
      currentPath : __dirname,
      stdio : 'pipe',
      outputPiping : 1,
    }
    _.process.startMinimal( o );

    /* ignores SIGTERM until child process will be terminated */
    process.on( 'SIGTERM', () =>
    {
      o.conTerminate.catch( ( err ) =>
      {
        _.errLogOnce( err );
        return null;
      })
    })
  }

  /* */

}

startMinimalOptionTimeOut.timeOut = 1e6;
startMinimalOptionTimeOut.rapidity = -1;

//

function startAfterDeath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let program1Path = a.program( program1 );
  let program2Path = a.program( program2 );
  let program2PidPath = a.abs( a.routinePath, 'program2Pid' );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      let stack = [];
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        mode,
        outputCollecting : 1,
        outputPiping : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }

      if( mode === 'shell' ) /* mode::shell doesn't support ipc */
      return test.shouldThrowErrorSync( () => _.process.start( o ) )

      // debugger;
      _.process.start( o );
      let secondaryPid;
      // debugger;

      o.pnd.on( 'message', ( e ) =>
      {
        secondaryPid = _.numberFrom( e );
      })

      o.conTerminate.then( () =>
      {
        stack.push( 'conTerminate1' );

        test.will = 'program1 terminated'
        test.identical( o.exitCode, 0 );

        test.will = 'secondary process is alive'
        test.true( _.process.isAlive( secondaryPid ) );

        test.will = 'child of secondary process is still alive'
        test.true( !a.fileProvider.fileExists( program2PidPath ) );

        return _.time.out( context.t2 * 2 ); /* 10000 */
      })

      o.conTerminate.then( () =>
      {
        stack.push( 'conTerminate2' );
        test.identical( stack, [ 'conTerminate1', 'conTerminate2' ] );

        test.case = 'secondary process is terminated'
        test.true( !_.process.isAlive( secondaryPid ) );

        test.case = 'child of secondary process is terminated'
        test.true( a.fileProvider.fileExists( program2PidPath ) );
        let program2Pid = a.fileProvider.fileRead( program2PidPath );
        program2Pid = _.numberFrom( program2Pid );

        test.case = 'secondary process and child are not same'
        test.true( !_.process.isAlive( program2Pid ) );
        test.notIdentical( secondaryPid, program2Pid );

        a.fileProvider.fileDelete( program2PidPath );
        return null;
      })

      return o.conTerminate;
    })

    return ready;

  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   let o =
  //   {
  //     execPath : 'node program1.js',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     outputPiping : 1,
  //     currentPath : a.routinePath,
  //     ipc : 1,
  //   }
  //   // debugger;
  //   _.process.startMinimal( o );
  //   let secondaryPid;
  //   // debugger;

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     secondaryPid = _.numberFrom( e );
  //   })

  //   o.conTerminate.then( () =>
  //   {
  //     stack.push( 'conTerminate1' );

  //     test.will = 'program1 terminated'
  //     test.identical( o.exitCode, 0 );

  //     test.will = 'secondary process is alive'
  //     test.true( _.process.isAlive( secondaryPid ) );

  //     test.will = 'child of secondary process is still alive'
  //     test.true( !a.fileProvider.fileExists( program2PidPath ) );

  //     return _.time.out( context.t2 * 2 ); /* 10000 */
  //   })

  //   o.conTerminate.then( () =>
  //   {
  //     stack.push( 'conTerminate2' );
  //     test.identical( stack, [ 'conTerminate1', 'conTerminate2' ] );

  //     test.case = 'secondary process is terminated'
  //     test.true( !_.process.isAlive( secondaryPid ) );

  //     test.case = 'child of secondary process is terminated'
  //     test.true( a.fileProvider.fileExists( program2PidPath ) );
  //     let program2Pid = a.fileProvider.fileRead( program2PidPath );
  //     program2Pid = _.numberFrom( program2Pid );

  //     test.case = 'secondary process and child are not same'
  //     test.true( !_.process.isAlive( program2Pid ) );
  //     test.notIdentical( secondaryPid, program2Pid );
  //     return null;
  //   })

  //   return o.conTerminate;
  // })

  // /*  */

  // return a.ready;

  /* - */

  function program1()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let o =
    {
      execPath : 'node program2.js',
      outputCollecting : 1,
      when : 'afterdeath',
      mode : 'spawn',
    }

    _.process.start( o );

    o.conStart.thenGive( () =>
    {
      process.send( o.pnd.pid );
    })

    _.time.out( context.t2, () => /* 5000 */
    {
      console.log( 'program1::termination begin' );
      _.procedure.terminationBegin();
      return null;
    })
  }

  /* */

  function program2()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wFiles' );

    _.time.out( context.t2, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'program2Pid' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
    })
  }

}

startAfterDeath.timeOut = 35e4; /* Locally : 34.737s */
startAfterDeath.description =
`
Spawns program1 as "main" process.
Program1 starts program2 with mode:'afterdeath'
Program2 is spawned after death of program1
Program2 exits normally after short timeout
`

//

function startAfterDeathOutput( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let program1Path = a.program( program1 );
  let program2Path = a.program( program2 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        mode,
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }

      if( mode === 'shell' ) /* mode::shell doesn't support ipc */
      return test.shouldThrowErrorSync( () => _.process.start( o ) );

      let con = _.process.start( o );

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'program1::begin' ), 1 )
        test.identical( _.strCount( op.output, 'program1::end' ), 1 )
        test.identical( _.strCount( op.output, 'program2::begin' ), 1 )
        test.identical( _.strCount( op.output, 'program2::end' ), 1 )

        return null;
      })

      return con;
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   let o =
  //   {
  //     execPath : 'node program1.js',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //     ipc : 1,
  //   }
  //   let con = _.process.startMinimal( o );

  //   con.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( _.strCount( op.output, 'program1::begin' ), 1 )
  //     test.identical( _.strCount( op.output, 'program1::end' ), 1 )
  //     test.identical( _.strCount( op.output, 'program2::begin' ), 1 )
  //     test.identical( _.strCount( op.output, 'program2::end' ), 1 )

  //     return null;
  //   })

  //   return con;
  // })

  // return a.ready;

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'program1::begin' );

    let o =
    {
      execPath : 'node program2.js',
      mode : 'spawn',
      currentPath : __dirname,
      when : 'afterdeath',
      stdio : 'inherit'
    }

    _.process.start( o );

    o.pnd.on( 'exit', () => //zzz for Vova: remove after enabling exit handler in start
    {
      _.procedure.terminationBegin();
    })

    _.time.out( context.t2, () =>
    {
      console.log( 'program1::end' );
      o.pnd.disconnect();
      return null;
    })
  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'program2::begin' );

    _.time.out( context.t2, () =>
    {
      console.log( 'program2::end' );
    })
  }
}

startAfterDeathOutput.timeOut = 27e4; /* Locally : 26.485s */
startAfterDeathOutput.description =
`
Fakes death of program1 and checks output of program2
`

// --
// detaching
// --

function startMinimalDetachingResourceReady( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, consequence receives resources after child`;
      let track = [];

      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        detaching : 1,
        currentPath : a.routinePath,
        throwingExitCode : 0
      }
      let result = _.process.startMinimal( o );

      test.true( result !== o.conStart );
      test.true( result !== o.conTerminate );

      o.conStart.thenGive( ( op ) =>
      {
        track.push( 'conStart' );
        test.true( _.mapIs( op ) );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) );
        o.pnd.kill();
        return null;
      })

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.notIdentical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, 'SIGTERM' );
        test.identical( track, [ 'conStart', 'conTerminate' ] );
        return null;
      })

      return o.conTerminate;
    })

    return ready;
  }

  /* */


  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }
}

//

function startMinimalDetachingNoTerminationBegin( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testFilePath = a.abs( a.routinePath, 'testFile' );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, stdio:ignore ipc:false, parent should wait for child to exit`;

      if( mode === 'fork' ) /* In mode::fork option::ipc must be true.*/
      return test.true( true );

      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );
      let o =
      {
        execPath : 'node testAppParent.js stdio : ignore ipc : false outputPiping : 0 outputCollecting : 0',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }

      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent and child are dead';
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        if( mode === 'shell' && process.platform !== 'darwin' ) /* process in mode::shell on windows and linux has 2 processes: terminal and application */
        test.true( !_.process.isAlive( childPid ) );
        else
        test.identical( data.childPid, childPid );

        a.fileProvider.fileDelete( testAppParentPath );
        a.fileProvider.fileDelete( testAppChildPath );
        return null;
      })

      return con;
    })

    /*  */

    .then( () =>
    {
      test.case = `mode : ${mode}, stdio:ignore ipc:true, parent should wait for child to exit`;

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication. */
      return test.true( true );

      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );

      let o =
      {
        execPath : 'node testAppParent.js stdio : ignore ipc : true outputPiping : 0 outputCollecting : 0',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }

      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent and child are dead';
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        test.identical( data.childPid, childPid )

        a.fileProvider.fileDelete( testAppParentPath );
        a.fileProvider.fileDelete( testAppChildPath );
        return null;
      })

      return con;
    })

    /*  */

    .then( () =>
    {
      test.case = `mode : ${mode}, stdio:pipe, parent should wait for child to exit`;
      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );

      let o =
      {
        execPath : 'node testAppParent.js stdio : pipe',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent and child are dead';
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        if( mode === 'shell' && process.platform !== 'darwin' ) /* process in mode::shell on windows and linux has 2 processes: terminal and application */
        test.true( !_.process.isAlive( childPid ) );
        else
        test.identical( data.childPid, childPid );

        a.fileProvider.fileDelete( testAppParentPath );
        a.fileProvider.fileDelete( testAppChildPath );
        return null;
      })

      return con;
    })

    /*  */

    .then( () =>
    {
      test.case = `mode : ${mode}, stdio:pipe ipc:true, parent should wait for child to exit`;

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication. */
      return test.true( true );

      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );

      let o =
      {
        execPath : 'node testAppParent.js stdio : pipe ipc : true',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }


      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent and child are dead';
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        test.identical( data.childPid, childPid )

        a.fileProvider.fileDelete( testAppParentPath );
        a.fileProvider.fileDelete( testAppChildPath );
        return null;
      })

      return con;
    })

    return ready;
  }

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let args = _.process.input();

    let o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      mode,
      ipc : mode === 'fork' ? 1 : 0,
      detaching : true,
    }

    _.mapExtend( o, args.map );
    if( o.ipc !== undefined )
    o.ipc = _.boolFrom( o.ipc );

    _.process.startMinimal( o );

    process.send({ childPid : o.pnd.pid });
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachingNoTerminationBegin.rapidity = -1;
startMinimalDetachingNoTerminationBegin.timeOut = 63e4; /* Locally : 62.137s */

//

function startMinimalDetachedOutputStdioIgnore( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppParentPath = a.program( testAppParent );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, stdio : ignore, no output from detached child`;

      let o =
      {
        execPath : `node testAppParent.js mode : ${mode} stdio : ignore`,
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
      }
      let con = _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 )
        test.true( !_.strHas( o.output, 'Child process start' ) )
        test.true( !_.strHas( o.output, 'Child process end' ) )
        return null;
      })

      return con;
    })

    return ready;

  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'mode : spawn, stdio : ignore, no output from detached child';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : spawn stdio : ignore',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )
  //     test.true( !_.strHas( o.output, 'Child process start' ) )
  //     test.true( !_.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : fork, stdio : ignore, no output from detached child';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : fork stdio : ignore',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )
  //     test.true( !_.strHas( o.output, 'Child process start' ) )
  //     test.true( !_.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : shell, stdio : ignore, no output from detached child';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : shell stdio : ignore',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )
  //     test.true( !_.strHas( o.output, 'Child process start' ) )
  //     test.true( !_.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let args = _.process.input();

    let o =
    {
      execPath : 'testAppChild.js',
      detaching : true,
    }

    _.mapExtend( o, args.map );
    if( o.ipc !== undefined )
    o.ipc = _.boolFrom( o.ipc );

    if( o.mode !== 'fork' )
    o.execPath = 'node ' + o.execPath;

    _.process.startMinimal( o );
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachedOutputStdioIgnore.timeOut = 23e4; /* Locally : 22.959s */

//

function startMinimalDetachedOutputStdioPipe( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppParentPath = a.program( testAppParent );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, stdio : pipe`;

      let o =
      {
        execPath : `node testAppParent.js mode : ${mode} stdio : pipe`,
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
      }
      let con = _.process.startMinimal( o );

      con.then( () =>
      {
        test.identical( o.exitCode, 0 );

        /*
        zzz for Vova: output piping doesn't work as expected in mode "shell" on windows
        investigate if its fixed in never verions of node or implement alternative solution
        */

        if( process.platform === 'win32' && mode === 'shell' )
        return null;

        test.true( _.strHas( o.output, 'Child process start' ) )
        test.true( _.strHas( o.output, 'Child process end' ) )
        return null;
      })

      return con;
    })

    return ready;

  }

  /* */

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'mode : spawn, stdio : pipe';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : spawn stdio : pipe',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )
  //     test.true( _.strHas( o.output, 'Child process start' ) )
  //     test.true( _.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : fork, stdio : pipe';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : fork stdio : pipe',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )
  //     test.true( _.strHas( o.output, 'Child process start' ) )
  //     test.true( _.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : shell, stdio : pipe';

  //   let o =
  //   {
  //     execPath : 'node testAppParent.js mode : shell stdio : pipe',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //   }
  //   let con = _.process.start( o );

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, 0 )

  //     /*
  //     zzz for Vova: output piping doesn't work as expected in mode "shell" on windows
  //     investigate if its fixed in never verions of node or implement alternative solution
  //     */

  //     if( process.platform === 'win32' )
  //     return null;

  //     test.true( _.strHas( o.output, 'Child process start' ) )
  //     test.true( _.strHas( o.output, 'Child process end' ) )
  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // return a.ready;

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let args = _.process.input();

    let o =
    {
      execPath : 'testAppChild.js',
      detaching : true,
    }

    _.mapExtend( o, args.map );
    if( o.ipc !== undefined )
    o.ipc = _.boolFrom( o.ipc );

    if( o.mode !== 'fork' )
    o.execPath = 'node ' + o.execPath;

    _.process.startMinimal( o );
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachedOutputStdioPipe.timeOut = 22e4; /* Locally : 22.906s */

//

function startMinimalDetachedOutputStdioInherit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );

  /* */

  test.true( true );

  if( !Config.debug )
  return a.ready;

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, stdio : inherit`;
      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        stdio : 'inherit',
        detaching : 1,
        currentPath : a.routinePath,
      }
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'mode : spawn, stdio : inherit';
  //   let o =
  //   {
  //     execPath : 'node testAppChild.js',
  //     mode : 'spawn',
  //     stdio : 'inherit',
  //     detaching : 1,
  //     currentPath : a.routinePath,
  //   }
  //   return test.shouldThrowErrorSync( () => _.process.start( o ) );
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : fork, stdio : inherit';
  //   let o =
  //   {
  //     execPath : 'testAppChild.js',
  //     mode : 'fork',
  //     stdio : 'inherit',
  //     detaching : 1,
  //     currentPath : a.routinePath,
  //   }
  //   return test.shouldThrowErrorSync( () => _.process.start( o ) );
  // })

  // /*  */

  // .then( () =>
  // {
  //   test.case = 'mode : shell, stdio : inherit';
  //   let o =
  //   {
  //     execPath : 'node testAppChild.js',
  //     mode : 'shell',
  //     stdio : 'inherit',
  //     detaching : 1,
  //     currentPath : a.routinePath,
  //   }
  //   return test.shouldThrowErrorSync( () => _.process.start( o ) );
  // })

  // /*  */

  // return a.ready;

  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }
}

//

function startMinimalDetachingIpc( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    ready
    .then( () =>
    {
      test.case = `mode : ${mode}, stdio : ignore`;

      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        outputPiping : 0,
        outputCollecting : 0,
        stdio : 'ignore',
        currentPath : a.routinePath,
        detaching : 1,
        ipc : 1,
      }

      if( mode === 'shell' )
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );

      _.process.startMinimal( o );

      let message;

      o.pnd.on( 'message', ( e ) =>
      {
        message = e;
      })

      o.conStart.thenGive( () =>
      {
        track.push( 'conStart' );
        o.pnd.send( 'child' );
      })

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( message, 'child' );
        test.identical( track, [ 'conStart', 'conTerminate' ] );
        track = [];
        return null;
      })

      return o.conTerminate;
    })

    /*  */

    .then( () =>
    {
      test.case = `mode : ${mode}, stdio : pipe`;

      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        outputCollecting : 1,
        stdio : 'pipe',
        currentPath : a.routinePath,
        detaching : 1,
        ipc : 1,
      }

      if( mode === 'shell' )
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );

      _.process.startMinimal( o );

      let message;

      o.pnd.on( 'message', ( e ) =>
      {
        message = e;
      })

      o.conStart.thenGive( () =>
      {
        track.push( 'conStart' );
        o.pnd.send( 'child' );
      })

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( message, 'child' );
        test.identical( track, [ 'conStart', 'conTerminate' ] );
        track = [];
        return null;
      })

      return o.conTerminate;
    })

    return ready;

  }

  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    process.on( 'message', ( data ) =>
    {
      process.send( data );
      process.exit();
    })

  }
}

//

function startMinimalDetachingTrivial( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    if( mode === 'shell' ) /* mode::shell doesn't support ipc */
    return test.true( true );

    ready.then( () =>
    {
      a.reflect();
      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${mode}, trivial use case`;

      let testFilePath = a.abs( a.routinePath, 'testFile' );
      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );

      let o =
      {
        execPath : 'testAppParent.js',
        outputCollecting : 1,
        mode : 'fork',
        stdio : 'pipe',
        detaching : 0,
        throwingExitCode : 0,
        currentPath : a.routinePath,
      }

      _.process.startMinimal( o );

      var childPid;
      o.pnd.on( 'message', ( e ) =>
      {
        childPid = _.numberFrom( e );
      })

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.true( _.process.isAlive( childPid ) );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'Child process start' ) );
        test.true( _.strHas( op.output, 'from parent: data' ) );
        test.true( !_.strHas( op.output, 'Child process end' ) );
        test.identical( o.exitCode, op.exitCode );
        test.identical( o.output, op.output );
        return _.time.out( context.t2 * 2 ); /* 10000 */
      })

      o.conTerminate.then( () =>
      {
        track.push( 'conTerminate' );
        test.true( !_.process.isAlive( childPid ) );

        let childPidFromFile = a.fileProvider.fileRead( testFilePath );
        childPidFromFile = _.numberFrom( childPidFromFile )
        test.true( !_.process.isAlive( childPidFromFile ) );
        test.identical( childPid, childPidFromFile )
        test.identical( track, [ 'conTerminate', 'conTerminate' ] );

        return null;
      })

      return o.conTerminate;
    })

    return ready;

  }

  /* */

  /* ORIGINAL */
  // test.case = 'trivial use case';

  // let o =
  // {
  //   execPath : 'testAppParent.js',
  //   outputCollecting : 1,
  //   mode : 'fork',
  //   stdio : 'pipe',
  //   detaching : 0,
  //   throwingExitCode : 0,
  //   currentPath : a.routinePath,
  // }

  // _.process.start( o );

  // var childPid;
  // o.pnd.on( 'message', ( e ) =>
  // {
  //   childPid = _.numberFrom( e );
  // })

  // o.conTerminate.then( ( op ) =>
  // {
  //   track.push( 'conTerminate' );
  //   test.true( _.process.isAlive( childPid ) );
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.true( _.strHas( op.output, 'Child process start' ) );
  //   test.true( _.strHas( op.output, 'from parent: data' ) );
  //   test.true( !_.strHas( op.output, 'Child process end' ) );
  //   test.identical( o.exitCode, op.exitCode );
  //   test.identical( o.output, op.output );
  //   return _.time.out( context.t2 * 2 ); /* 10000 */
  // })

  // o.conTerminate.then( () =>
  // {
  //   track.push( 'conTerminate' );
  //   test.true( !_.process.isAlive( childPid ) );

  //   let childPidFromFile = a.fileProvider.fileRead( testFilePath );
  //   childPidFromFile = _.numberFrom( childPidFromFile )
  //   test.true( !_.process.isAlive( childPidFromFile ) );
  //   test.identical( childPid, childPidFromFile )
  //   test.identical( track, [ 'conTerminate', 'conTerminate' ] );
  //   return null;
  // })

  // return o.conTerminate;

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    let o =
    {
      execPath : 'testAppChild.js',
      mode,
      outputCollecting : 1,
      stdio : 'pipe',
      detaching : 1,
      applyingExitCode : 0,
      throwingExitCode : 0,
      outputPiping : 1,
      ipc : 1,
    }
    _.process.startNjs( o );

    o.conStart.thenGive( () =>
    {
      process.send( o.pnd.pid )
      o.pnd.send( 'data' );
      o.pnd.on( 'message', () =>
      {
        o.disconnect();
      })
    })
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    process.on( 'message', ( data ) =>
    {
      console.log( 'from parent:', data );
      process.send( 'ready to disconnect' )
    })

    _.time.out( context.t2, () => /* 5000 */
    {
      console.log( 'Child process end' );
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      return null;
    })

  }
}

startMinimalDetachingTrivial.timeOut = 26e4; /* Locally : 25.972s */

//

function startMinimalEventClose( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program({ routine : program1 });
  let data = [];

  let modes = [ 'spawn', 'fork', 'shell' ];
  let ipc = [ false, true ]
  let disconnecting = [ false, true ];

  modes.forEach( mode =>
  {
    ipc.forEach( ipc =>
    {
      disconnecting.forEach( disconnecting =>
      {
        a.ready.then( () => run( mode,ipc,disconnecting ) );
      })
    })
  })

  a.ready.then( () =>
  {
    var dim = [ data.length / 4, 4 ];
    var style = 'doubleBorder';
    var topHead = [ 'mode', 'ipc', 'disconnecting', 'event close' ];
    var got = _.strTable({ data, dim, style, topHead, colWidth : 18 });

    var exp =
`
╔════════════════════════════════════════════════════════════════════════╗
║       mode               ipc          disconnecting      event close   ║
╟────────────────────────────────────────────────────────────────────────╢
║       spawn             false             false             true       ║
║       spawn             false             true              true       ║
║       spawn             true              false             true       ║
║       spawn             true              true              false      ║
║       fork              true              false             true       ║
║       fork              true              true              false      ║
║       shell             false             false             true       ║
║       shell             false             true              true       ║
╚════════════════════════════════════════════════════════════════════════╝
`
    test.equivalent( got.result, exp );
    console.log( got.result )
    return null;
  })

  return a.ready;

  /* - */

  function run( mode, ipc, disconnecting )
  {
    let ready = new _.Consequence().take( null );

    if( ipc && mode === 'shell' )
    return ready;

    if( !ipc && mode === 'fork' )
    return ready;

    let result = [ mode, ipc, disconnecting, false ];

    ready.then( () =>
    {
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        stdio : 'ignore',
        detaching : 0,
        mode,
        ipc,
      }

      test.case = _.toJs({ mode, ipc, disconnecting });

      _.process.startMinimal( o );

      o.conStart.thenGive( () =>
      {
        if( disconnecting )
        o.disconnect()
      })
      o.pnd.on( 'close', () =>
      {
        result[ 3 ] = true;
      })

      return _.time.out( context.t1 * 3, () =>
      {
        test.true( !_.process.isAlive( o.pnd.pid ) );

        if( mode === 'shell' )
        test.identical( result[ 3 ], true )

        if( mode === 'spawn' )
        test.identical( result[ 3 ], ipc && disconnecting ? false : true )

        if( mode === 'fork' )
        test.identical( result[ 3 ], !disconnecting )

        data.push.apply( data, result );
        return null;
      })
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath )
    console.log( 'program1::begin' );
    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 2 );
  }
}

startMinimalEventClose.timeOut = 5e5;
startMinimalEventClose.description =
`
Check if close event is called.
`

//

function startMinimalEventExit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program({ routine : program1 });
  let data = [];
  let modes = [ 'spawn', 'fork', 'shell' ];
  let stdio = [ 'inherit', 'pipe', 'ignore' ];
  let ipc = [ false, true ]
  let detaching = [ false, true ]
  let disconnecting = [ false, true ];

  modes.forEach( mode =>
  {
    stdio.forEach( stdio =>
    {
      ipc.forEach( ipc =>
      {
        detaching.forEach( detaching =>
        {
          disconnecting.forEach( disconnecting =>
          {
            a.ready.then(() => run( mode, stdio, ipc, detaching, disconnecting ) );
          })
        })
      })
    })
  })

  a.ready.then( () =>
  {
    var dim = [ data.length / 6, 6 ];
    var style = 'doubleBorder';
    var topHead = [ 'mode', 'stdio','ipc', 'detaching', 'disconnecting', 'event exit' ];
    var got = _.strTable({ data, dim, style, topHead, colWidth : 18 });

    var exp =
`
╔════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║       mode              stdio              ipc            detaching       disconnecting      event exit    ║
╟────────────────────────────────────────────────────────────────────────────────────────────────────────────╢
║       spawn            inherit            false             false             false             true       ║
║       spawn            inherit            false             true              false             true       ║
║       spawn            inherit            true              false             false             true       ║
║       spawn            inherit            true              true              false             true       ║
║       spawn             pipe              false             false             false             true       ║
║       spawn             pipe              false             true              false             true       ║
║       spawn             pipe              false             false             true              true       ║
║       spawn             pipe              false             true              true              true       ║
║       spawn             pipe              true              false             false             true       ║
║       spawn             pipe              true              true              false             true       ║
║       spawn             pipe              true              false             true              true       ║
║       spawn             pipe              true              true              true              true       ║
║       spawn            ignore             false             false             false             true       ║
║       spawn            ignore             false             true              false             true       ║
║       spawn            ignore             false             false             true              true       ║
║       spawn            ignore             false             true              true              true       ║
║       spawn            ignore             true              false             false             true       ║
║       spawn            ignore             true              true              false             true       ║
║       spawn            ignore             true              false             true              true       ║
║       spawn            ignore             true              true              true              true       ║
║       fork             inherit            true              false             false             true       ║
║       fork             inherit            true              true              false             true       ║
║       fork              pipe              true              false             false             true       ║
║       fork              pipe              true              true              false             true       ║
║       fork              pipe              true              false             true              true       ║
║       fork              pipe              true              true              true              true       ║
║       fork             ignore             true              false             false             true       ║
║       fork             ignore             true              true              false             true       ║
║       fork             ignore             true              false             true              true       ║
║       fork             ignore             true              true              true              true       ║
║       shell            inherit            false             false             false             true       ║
║       shell            inherit            false             true              false             true       ║
║       shell             pipe              false             false             false             true       ║
║       shell             pipe              false             true              false             true       ║
║       shell             pipe              false             false             true              true       ║
║       shell             pipe              false             true              true              true       ║
║       shell            ignore             false             false             false             true       ║
║       shell            ignore             false             true              false             true       ║
║       shell            ignore             false             false             true              true       ║
║       shell            ignore             false             true              true              true       ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════╝
`
    test.equivalent( got.result, exp );

    console.log( got.result )
    return null;
  })

  return a.ready;

  /* - */

  function run( mode, stdio, ipc, detaching, disconnecting )
  {
    let ready = new _.Consequence().take( null );

    if( detaching && stdio === 'inherit' ) /* remove if assert in start is removed */
    return ready;

    if( ipc && mode === 'shell' )
    return ready;

    if( !ipc && mode === 'fork' )
    return ready;

    let result = [ mode, stdio, ipc, disconnecting, detaching, false ];

    ready.then( () =>
    {
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        outputPiping : 0,
        outputCollecting : 0,
        stdio,
        mode,
        ipc,
        detaching
      }

      test.case = _.toJs({ mode, stdio, ipc, disconnecting, detaching });

      _.process.startMinimal( o );

      o.conStart.thenGive( () =>
      {
        if( disconnecting )
        o.disconnect()
      })
      o.pnd.on( 'exit', () =>
      {
        result[ 5 ] = true;
      })

      return _.time.out( context.t1 * 3, () =>
      {
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.identical( result[ 5 ], true );
        data.push.apply( data, result );
        return null;
      })
    })

    return ready;
  }

  /* - */

  function program1()
  {
    setTimeout( () => {}, context.t1 );
  }
}

startMinimalEventExit.rapidity = -1;
startMinimalEventExit.timeOut = 5e5;
startMinimalEventExit.description =
`
Check if exit event is called.
`

//

function startMinimalDetachingChildExitsAfterParent( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}, parent disconnects detached child process and exits, child contiues to work`;
      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );
      let testFilePath = a.abs( a.routinePath, 'testFile' );

      let o =
      {
        execPath : 'node testAppParent.js',
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
        currentPath : a.routinePath,
        detaching : 0,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let childPid;

      o.pnd.on( 'message', ( e ) =>
      {
        childPid = _.numberFrom( e );
      })

      o.conTerminate.then( ( op ) =>
      {
        test.will = 'parent is dead, detached child is still running'
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( _.process.isAlive( childPid ) );
        return _.time.out( context.t1 * 10 ); /* 10000 */ /* zzz */
      })

      o.conTerminate.then( () =>
      {
        let childPid2 = a.fileProvider.fileRead( testFilePath );
        childPid2 = _.numberFrom( childPid2 )
        test.true( !_.process.isAlive( childPid2 ) );
        if( process.platform === 'darwin' || mode !== 'shell' ) /* On Windows and Linux intermidiate process is created in mode::shell */
        test.identical( childPid, childPid2 );

        return null;
      })

      return o.conTerminate;
    })

    return ready;

  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'parent disconnects detached child process and exits, child contiues to work'
  //   let o =
  //   {
  //     execPath : 'node testAppParent.js',
  //     mode : 'spawn',
  //     stdio : 'pipe',
  //     outputPiping : 1,
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //     detaching : 0,
  //     ipc : 1,
  //   }
  //   let con = _.process.start( o );

  //   let childPid;

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     childPid = _.numberFrom( e );
  //   })

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.will = 'parent is dead, detached child is still running'
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.true( _.process.isAlive( childPid ) );
  //     return _.time.out( context.t2 * 2 ); /* 10000 */ /* zzz */
  //   })

  //   o.conTerminate.then( () =>
  //   {
  //     let childPid2 = a.fileProvider.fileRead( testFilePath );
  //     childPid2 = _.numberFrom( childPid2 )
  //     test.true( !_.process.isAlive( childPid2 ) );
  //     test.identical( childPid, childPid2 )
  //     return null;
  //   })

  //   return o.conTerminate;
  // })

  // /*  */

  // return a.ready;

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      stdio : 'ignore',
      outputPiping : 0,
      outputCollecting : 0,
      detaching : true,
      mode,
    }

    _.process.startMinimal( o );

    process.send( o.pnd.pid );

    _.time.out( context.t1, () => o.disconnect() ); /* 1000 */
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' );

    _.time.out( context.t1 * 5, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' );
    })
  }
}

startMinimalDetachingChildExitsAfterParent.timeOut = 36e4; /* Locally : 35.792s */
startMinimalDetachingChildExitsAfterParent.description =
`
Parent starts child process in detached mode and disconnects it.
Child process continues to work for at least 5 seconds after parent exits.
After 5 seconds child process creates test file in working directory and exits.
`

//

function startMinimalDetachingChildExitsBeforeParent( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}, parent disconnects detached child process and exits, child contiues to work`;
      let testAppParentPath = a.program({ routine : testAppParent, locals : { mode } });
      let testAppChildPath = a.program( testAppChild );
      let testFilePath = a.abs( a.routinePath, 'testFile' );

      let o =
      {
        execPath : 'node testAppParent.js',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      _.process.startMinimal( o );

      let child;
      let onChildTerminate = new _.Consequence();

      o.pnd.on( 'message', ( e ) =>
      {
        child = e;
        onChildTerminate.take( e );
      })

      onChildTerminate.then( () =>
      {
        let childPid = a.fileProvider.fileRead( testFilePath );
        test.true( _.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( _.numberFrom( childPid ) ) );
        return null;
      })

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );

        test.will = 'parent and chid are dead';

        test.identical( child.err, undefined );
        test.identical( child.exitCode, 0 );

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( child.pid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid )
        test.true( !_.process.isAlive( childPid ) );

        if( process.platform === 'darwin' || mode !== 'shell' ) /* On Windows and Linux intermidiate process is created in mode::shell */
        test.identical( child.pid, childPid );

        return null;
      })

      return _.Consequence.AndKeep( onChildTerminate, o.conTerminate );
    })

    return ready;
  }

  /* */

  /* ORIGINAL */
  // a.ready
  // .then( () =>
  // {
  //   let o =
  //   {
  //     execPath : 'node testAppParent.js',
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     currentPath : a.routinePath,
  //     ipc : 1,
  //   }
  //   _.process.start( o );

  //   let child;
  //   let onChildTerminate = new _.Consequence();

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     child = e;
  //     onChildTerminate.take( e );
  //   })

  //   onChildTerminate.then( () =>
  //   {
  //     let childPid = a.fileProvider.fileRead( testFilePath );
  //     test.true( _.process.isAlive( o.pnd.pid ) );
  //     test.true( !_.process.isAlive( _.numberFrom( childPid ) ) );
  //     return null;
  //   })

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );

  //     test.will = 'parent and chid are dead';

  //     test.identical( child.err, undefined );
  //     test.identical( child.exitCode, 0 );

  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.true( !_.process.isAlive( child.pid ) );

  //     test.true( a.fileProvider.fileExists( testFilePath ) );
  //     let childPid = a.fileProvider.fileRead( testFilePath );
  //     childPid = _.numberFrom( childPid )
  //     test.true( !_.process.isAlive( childPid ) );

  //     test.identical( child.pid, childPid );

  //     return null;
  //   })

  //   return _.Consequence.AndKeep( onChildTerminate, o.conTerminate );
  // })

  // /*  */

  // return a.ready;

  /* - */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      stdio : 'ignore',
      outputPiping : 0,
      outputCollecting : 0,
      detaching : true,
      mode,

    }

    _.process.startMinimal( o );

    o.conTerminate.finally( ( err, op ) =>
    {
      process.send({ exitCode : op.exitCode, err, pid : o.pnd.pid });
      return null;
    })

    _.time.out( context.t1 * 5, () => /* 5000 */
    {
      console.log( 'Parent process end' )
    });
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t1, () => /* 1000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachingChildExitsBeforeParent.timeOut = 21e4; /* Locally : 20.817s */
startMinimalDetachingChildExitsBeforeParent.description =
`
Parent starts child process in detached mode and registers callback to wait for child process.
Child process creates test file after 1 second and exits.
Callback in parent recevies message. Parent exits.
`

//

function startMinimalDetachingDisconnectedEarly( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  // let modes = [ 'fork', 'spawn', 'shell' ];
  let modes = [ 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    ready
    .then( () =>
    {
      test.case = `detaching on, disconnected forked child, mode:${mode}`;
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1,
      }

      let result = _.process.startMinimal( o );

      test.identical( o.ready.argumentsCount(), 0 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), 0 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 0 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 0 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 0 );

      test.identical( o.state, 'started' );
      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )

      test.identical( o.state, 'started' );
      o.disconnect();
      test.identical( o.state, 'disconnected' );

      o.conStart.finally( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) );
        return null;
      })

      o.conDisconnect.finally( ( err, op ) =>
      {
        track.push( 'conDisconnect' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) )
        return null;
      })

      o.conTerminate.finally( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( err, _.dont );
        return null;
      })

      result = _.time.out( context.t2, () => /* 5000 */
      {
        test.identical( o.state, 'disconnected' );
        test.identical( o.ended, true );
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate' ] );
        test.true( !_.process.isAlive( o.pnd.pid ) );
        return null;
      })

      return _.Consequence.AndTake( o.conStart, result );
    })

    /* */

    return ready;
  }

  /* */

  function program1()
  {
    console.log( 'program1:begin' );
    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 2 ); /* 2000 */
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
  }
}

startMinimalDetachingDisconnectedEarly.description =
`
Parent starts child process in detached mode and disconnects it right after start.
Child process creates test file after 2 second and stays alive.
conStart recevies message when process starts.
conDisconnect recevies message on disconnect which happen without delay.
conTerminate does not recevie an message.
Test routine waits for few seconds and checks if child is alive.
ProcessWatched should not throw any error.
`

//

function startMinimalDetachingDisconnectedLate( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    ready
    .then( () =>
    {
      test.case = `detaching on, disconnected forked child, mode:${mode}`;
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1,
      }

      let result = _.process.startMinimal( o );

      test.identical( o.ready.argumentsCount(), 0 );
      test.identical( o.ready.errorsCount(), 0 );
      test.identical( o.ready.competitorsCount(), 0 );
      test.identical( o.conStart.argumentsCount(), 1 );
      test.identical( o.conStart.errorsCount(), 0 );
      test.identical( o.conStart.competitorsCount(), 0 );
      test.identical( o.conDisconnect.argumentsCount(), 0 );
      test.identical( o.conDisconnect.errorsCount(), 0 );
      test.identical( o.conDisconnect.competitorsCount(), 0 );
      test.identical( o.conTerminate.argumentsCount(), 0 );
      test.identical( o.conTerminate.errorsCount(), 0 );
      test.identical( o.conTerminate.competitorsCount(), 0 );

      test.identical( o.state, 'started' );

      _.time.begin( context.t1, () => /* 1000 */
      {
        test.identical( o.state, 'started' );
        o.disconnect();
        test.identical( o.state, 'disconnected' );
      });

      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )

      o.conStart.finally( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) )
        return null;
      })

      o.conDisconnect.finally( ( err, op ) =>
      {
        track.push( 'conDisconnect' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) )
        return null;
      })

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( err, _.dont );
      })

      result = _.time.out( context.t1 * 5, () => /* 5000 */
      {
        test.identical( o.state, 'disconnected' );
        test.identical( o.ended, true );
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate' ] );
        test.true( !_.process.isAlive( o.pnd.pid ) )
        return null;
      })

      return _.Consequence.AndTake( o.conStart, result );
    })

    /* */

    return ready;
  }

  /* */

  function program1()
  {
    console.log( 'program1:begin' );
    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 2 ); /* 2000 */
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
  }
}

startMinimalDetachingDisconnectedLate.description =
`
Parent starts child process in detached mode and disconnects after short delay.
Child process creates test file after 2 second and stays alive.
conStart recevies message when process starts.
conDisconnect recevies message on disconnect which happen with short delay.
conTerminate does not recevie an message.
Test routine waits for few seconds and checks if child is alive.
ProcessWatched should not throw any error.
`

//

function startMinimalDetachingChildExistsBeforeParentWaitForTermination( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, detaching on, disconnected child`
      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      _.process.startMinimal( o );

      o.conTerminate.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( !_.process.isAlive( o.pnd.pid ) )
        return null;
      })

      return o.conTerminate;
    })

    return ready;
  }
  /* ORIGINAL */
  // .then( () =>
  // {
  //   test.case = 'detaching on, disconnected forked child'
  //   let o =
  //   {
  //     execPath : 'testAppChild.js',
  //     mode : 'fork',
  //     stdio : 'ignore',
  //     outputPiping : 0,
  //     outputCollecting : 0,
  //     currentPath : a.routinePath,
  //     detaching : 1
  //   }

  //   _.process.start( o );

  //   o.conTerminate.finally( ( err, op ) =>
  //   {
  //     test.identical( err, undefined );
  //     test.identical( op, o );
  //     test.true( !_.process.isAlive( o.pnd.pid ) )
  //     return null;
  //   })

  //   return o.conTerminate;
  // })

  // return a.ready;

  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var args = _.process.input();

    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachingChildExistsBeforeParentWaitForTermination.timeOut = 12e4; /* Locally : 11.380s */
startMinimalDetachingChildExistsBeforeParentWaitForTermination.description =
`
Parent starts child process in detached mode.
Test routine waits until o.conTerminate resolves message about termination of the child process.
`

//

function startMinimalDetachingEndCompetitorIsExecuted( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let track = [];

    ready.then( () =>
    {
      test.case = `mode : ${mode}, detaching on, disconnected child`;

      let o =
      {
        execPath : mode === 'fork' ?  'testAppChild.js' : 'node testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )
      test.true( _.consequenceIs( o.conTerminate ) )

      o.conStart.finally( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( o.ended, false );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) );
        return null;
      })

      o.conTerminate.finally( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( o.ended, true );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( track, [ 'conStart', 'conTerminate' ] )
        test.true( !_.process.isAlive( o.pnd.pid ) )
        return null;
      })

      return _.Consequence.AndTake( o.conStart, o.conTerminate );
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'detaching on, disconnected forked child'
  //   let o =
  //   {
  //     execPath : 'testAppChild.js',
  //     mode : 'fork',
  //     stdio : 'ignore',
  //     outputPiping : 0,
  //     outputCollecting : 0,
  //     currentPath : a.routinePath,
  //     detaching : 1
  //   }

  //   let result = _.process.start( o );

  //   test.true( o.conStart !== result );
  //   test.true( _.consequenceIs( o.conStart ) )
  //   test.true( _.consequenceIs( o.conTerminate ) )

  //   o.conStart.finally( ( err, op ) =>
  //   {
  //     track.push( 'conStart' );
  //     test.identical( o.ended, false );
  //     test.identical( err, undefined );
  //     test.identical( op, o );
  //     test.true( _.process.isAlive( o.pnd.pid ) );
  //     return null;
  //   })

  //   o.conTerminate.finally( ( err, op ) =>
  //   {
  //     track.push( 'conTerminate' );
  //     test.identical( o.ended, true );
  //     test.identical( err, undefined );
  //     test.identical( op, o );
  //     test.identical( track, [ 'conStart', 'conTerminate' ] )
  //     test.true( !_.process.isAlive( o.pnd.pid ) )
  //     return null;
  //   })

  //   return _.Consequence.AndTake( o.conStart, o.conTerminate );
  // })

  // /* */

  // return a.ready;

  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var args = _.process.input();

    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalDetachingEndCompetitorIsExecuted.timeOut = 12e4; /* Locally : 11.249s */
startMinimalDetachingEndCompetitorIsExecuted.description =

`Parent starts child process in detached mode.
Consequence conStart recevices message when process starts.
Consequence conTerminate recevices message when process ends.
o.ended is false when conStart callback is executed.
o.ended is true when conTerminate callback is executed.
`

//

function startMinimalDetachingTerminationBegin( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testFilePath = a.abs( a.routinePath, 'testFile' );
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.then( () =>
    {
      a.fileProvider.filesDelete( a.routinePath );
      let locals = { mode }
      a.program({ routine : testAppParent, locals });
      a.program( testAppChild );
      return null;
    })

    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  });

  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = new _.Consequence().take( null )

    /*  */

    ready.then( () =>
    {
      test.case = `child mode:${mode} stdio:ignore ipc:0`

      a.fileProvider.filesDelete( testFilePath );
      a.fileProvider.dirMakeForFile( testFilePath );

      let o =
      {
        execPath : 'node testAppParent.js stdio : ignore outputPiping : 0 outputCollecting : 0',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.will = 'parent is dead, child is still alive';
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.process.isAlive( op.pnd.pid ) );
        test.true( _.process.isAlive( data.childPid ) );
        return _.time.out( context.t2 * 2 );
      })

      con.then( () =>
      {
        test.will = 'both dead';

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        console.log(  childPid );
        /* if shell then could be 2 processes, first - terminal, second application */
        if( mode !== 'shell' )
        test.identical( data.childPid, childPid );

        return null;
      })

      return con;
    })

    /*  */

    ready.then( () =>
    {
      test.case = `child mode:${mode} stdio:ignore ipc:1`

      a.fileProvider.filesDelete( testFilePath );
      a.fileProvider.dirMakeForFile( testFilePath );

      let o =
      {
        execPath : `node testAppParent.js stdio : ignore ${ mode === 'shell' ? '' : 'ipc:1'} outputPiping : 0 outputCollecting : 0`,
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent is dead, child is still alive';
        test.true( !_.process.isAlive( op.pnd.pid ) );
        test.true( _.process.isAlive( data.childPid ) );
        return _.time.out( context.t2 * 2 );
      })

      con.then( () =>
      {
        test.will = 'both dead';

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        /* if shell then could be 2 processes, first - terminal, second application */
        if( mode !== 'shell' )
        test.identical( data.childPid, childPid );

        return null;
      })

      return con;
    })

    /*  */

    ready.then( () =>
    {
      test.case = `child mode:${mode} stdio:pipe ipc:0`
      a.fileProvider.filesDelete( testFilePath );
      a.fileProvider.dirMakeForFile( testFilePath );

      let o =
      {
        execPath : 'node testAppParent.js stdio : pipe',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent is dead, child is still alive';
        test.true( !_.process.isAlive( op.pnd.pid ) );
        test.true( _.process.isAlive( data.childPid ) );
        return _.time.out( context.t2 * 2 );
      })

      con.then( () =>
      {
        test.will = 'both dead';

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        /* if shell then could be 2 processes, first - terminal, second application */
        if( mode !== 'shell' )
        test.identical( data.childPid, childPid )

        return null;
      })

      return con;
    })

    /*  */

    ready.then( () =>
    {
      test.case = `child mode:${mode} stdio:pipe ipc:1`

      a.fileProvider.filesDelete( testFilePath );
      a.fileProvider.dirMakeForFile( testFilePath );

      let o =
      {
        execPath : `node testAppParent.js stdio : pipe ${ mode === 'shell' ? '' : 'ipc:1'}`,
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );

      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.will = 'parent is dead, child is still alive';
        test.true( !_.process.isAlive( op.pnd.pid ) );
        test.true( _.process.isAlive( data.childPid ) );
        return _.time.out( context.t2 * 2 );
      })

      con.then( () =>
      {
        test.will = 'both dead';

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        /* if shell then could be 2 processes, first - terminal, second application */
        if( mode !== 'shell' )
        test.identical( data.childPid, childPid )

        return null;
      })

      return con;
    })

    return ready;
  }

  /*  */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let args = _.process.input();

    let o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      mode,
      detaching : true,
    }

    _.mapExtend( o, args.map );
    if( o.ipc !== undefined )
    o.ipc = _.boolFrom( o.ipc );

    _.process.startMinimal( o );

    console.log( o.pnd.pid )

    process.send({ childPid : o.pnd.pid });

    o.conStart.thenGive( () =>
    {
      _.procedure.terminationBegin();
    })
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    console.log( 'Child process start', process.pid )
    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }
}

startMinimalDetachingTerminationBegin.rapidity = -1;
startMinimalDetachingTerminationBegin.timeOut = 3e5;
startMinimalDetachingTerminationBegin.description =
`
Checks that detached child process continues to work after parent death.
Parent spawns child in detached mode with different stdio and ipc.
Child continues to work after parent death.
`
//

function startMinimalDetachingThrowing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );

  /* */

  test.true( true );

  if( !Config.debug )
  return;

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    test.case = `mode : ${mode}`;

    var o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      mode,
      stdio : 'inherit',
      currentPath : a.routinePath,
      detaching : 1
    }

    return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

  }

  /* ORIGINAL */
  // var o =
  // {
  //   execPath : 'node testAppChild.js',
  //   mode : 'spawn',
  //   stdio : 'inherit',
  //   currentPath : a.routinePath,
  //   detaching : 1
  // }
  // test.shouldThrowErrorSync( () => _.process.start( o ) )

  // /* */

  // var o =
  // {
  //   execPath : 'node testAppChild.js',
  //   mode : 'shell',
  //   stdio : 'inherit',
  //   currentPath : a.routinePath,
  //   detaching : 1
  // }
  // test.shouldThrowErrorSync( () => _.process.start( o ) )

  // /* */

  // var o =
  // {
  //   execPath : 'testAppChild.js',
  //   mode : 'fork',
  //   stdio : 'inherit',
  //   currentPath : a.routinePath,
  //   detaching : 1
  // }
  // test.shouldThrowErrorSync( () => _.process.start( o ) )

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( 'Child process start' )

    _.time.out( context.t2, () => /* 5000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }
}

//

function startNjsDetachingChildThrowing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, detached child throws error, conTerminate receives resource with error`;
      let track = [];

      let o =
      {
        execPath : 'testAppChild.js',
        mode,
        outputCollecting : 1,
        stdio : 'pipe',
        detaching : 1,
        applyingExitCode : 0,
        throwingExitCode : 0,
        outputPiping : 0,
        currentPath : a.routinePath,
      }

      _.process.startNjs( o );

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.notIdentical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' && process.platform === 'win32' ) /* on platform Windows in mode::shell no output from error.message */
        test.identical( op.output, '' );
        else
        test.true( _.strHas( op.output, 'Child process error' ) );
        test.identical( o.exitCode, op.exitCode );
        test.identical( o.output, op.output );
        test.identical( track, [ 'conTerminate' ] )
        return null;
      })

      return o.conTerminate;
    })

    return ready;

  }

  /* ORIGINAL */
  // test.case = 'detached child throws error, conTerminate receives resource with error';

  // let o =
  // {
  //   execPath : 'testAppChild.js',
  //   outputCollecting : 1,
  //   stdio : 'pipe',
  //   detaching : 1,
  //   applyingExitCode : 0,
  //   throwingExitCode : 0,
  //   outputPiping : 0,
  //   currentPath : a.routinePath,
  // }

  // _.process.startNjs( o );

  // o.conTerminate.then( ( op ) =>
  // {
  //   track.push( 'conTerminate' );
  //   test.notIdentical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.true( _.strHas( op.output, 'Child process error' ) );
  //   test.identical( o.exitCode, op.exitCode );
  //   test.identical( o.output, op.output );
  //   test.identical( track, [ 'conTerminate' ] )
  //   return null;
  // })

  // return o.conTerminate;

  /* - */

  function testAppChild()
  {
    setTimeout( () =>
    {
      throw new Error( 'Child process error' );
    }, context.t1 ); /* 1000 */
  }

}

// --
// on
// --

function startMinimalOnStart( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let track = [];

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  });

  return a.ready;

  /* */

  function run( mode )
  {
    let fork = mode === 'fork';
    let ready = new _.Consequence().take( null )

    /* */

    .then( () =>
    {
      test.case = 'detaching off, no errors'
      let o =
      {
        execPath : !fork ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 0
      }

      let result = _.process.startMinimal( o );

      test.notIdentical( o.conStart, result );
      test.true( _.consequenceIs( o.conStart ) )

      o.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) );
        return null;
      })

      result.then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return _.Consequence.AndTake( o.conStart, result );
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching off, error on spawn'
      let o =
      {
        execPath : 'unknownScript.js',
        mode,
        stdio : [ null, 'something', null ],
        currentPath : a.routinePath,
        detaching : 0
      }

      let result = _.process.startMinimal( o );

      test.notIdentical( o.conStart, result );
      test.true( _.consequenceIs( o.conStart ) )

      return test.shouldThrowErrorAsync( o.conTerminate );
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching off, error on spawn, no callback for conStart'
      let o =
      {
        execPath : 'unknownScript.js',
        mode,
        stdio : [ null, 'something', null ],
        currentPath : a.routinePath,
        detaching : 0
      }

      let result = _.process.startMinimal( o );

      test.notIdentical( o.conStart, result );
      test.true( _.consequenceIs( o.conStart ) )

      return test.shouldThrowErrorAsync( o.conTerminate );
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching on, conStart and result are same and give resource on start'
      let o =
      {
        execPath : !fork ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )

      o.conStart.then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.exitCode, null );
        test.identical( op.ended, false );
        test.identical( op.exitSignal, null );
        return null;
      })

      return _.Consequence.AndTake( o.conStart, o.conTerminate );
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching on, error on spawn'
      let o =
      {
        execPath : 'unknownScript.js',
        mode,
        stdio : [ 'ignore', 'ignore', 'ignore', null ],
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )

      result = test.shouldThrowErrorAsync( o.conTerminate );

      result.then( () => _.time.out( context.t1 * 2 ) ) /* 2000 */
      result.then( () =>
      {
        test.identical( o.conTerminate.resourcesCount(), 0 );
        return null;
      })

      return result;
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching on, disconnected child';
      track = [];
      let o =
      {
        execPath : !fork ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );

      o.conStart.finally( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.true( _.process.isAlive( o.pnd.pid ) )
        test.identical( o.state, 'started' );
        o.disconnect();
        return null;
      })

      o.conDisconnect.finally( ( err, op ) =>
      {
        track.push( 'conDisconnect' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.state, 'disconnected' );
        test.true( _.process.isAlive( o.pnd.pid ) );
        return null;
      })

      o.conTerminate.finally( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( err, _.dont );
        return null;
      })

      let ready = _.time.out( context.t2, () => /* 5000 */
      {
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate' ] );
      })

      return _.Consequence.AndTake( o.conStart, o.conDisconnect, ready );
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching on, disconnected forked child'
      let o =
      {
        execPath : !fork ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );

      o.conStart.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.state, 'started' )
        test.true( _.process.isAlive( o.pnd.pid ) )
        o.disconnect();
        return null;
      })

      o.conDisconnect.finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.state, 'disconnected' )
        test.true( _.process.isAlive( o.pnd.pid ) )
        return null;
      })

      result = _.time.out( context.t1 * 7, () => /* 2000 + context.t2 */
      {
        test.true( !_.process.isAlive( o.pnd.pid ) )
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.conTerminate.resourcesCount(), 1 );
        return null;
      })

      return _.Consequence.AndTake( o.conStart, o.conDisconnect, result );
    })

    /* */

    return ready;
  }


  /* */

  function testAppChild()
  {
    console.log( 'Child process begin' );

    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var args = _.process.input();

    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      console.log( 'Child process end' );
      return null;
    })
  }

}

startMinimalOnStart.timeOut = 3e5;
startMinimalOnStart.rapidity = -1;

//

function startMinimalOnTerminate( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  });

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null )

    .then( () =>
    {
      test.case = 'detaching off'
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 0
      }

      let result = _.process.startMinimal( o );

      test.true( o.conTerminate !== result );

      result.then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.state, 'terminated' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return result;
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching off, disconnect'
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        detaching : 0
      }
      let track = [];

      let result = _.process.startMinimal( o );

      o.disconnect();

      test.true( o.conTerminate !== result );

      o.conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( o, op );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return _.time.out( context.t1 * 7, () => /* 2000 + context.t2 */
      {
        test.identical( o.state, 'disconnected' );
        test.identical( o.ended, true );
        test.identical( track, [] );
        test.identical( o.conTerminate.argumentsCount(), 0 );
        test.identical( o.conTerminate.errorsCount(), 1 );
        test.identical( o.conTerminate.competitorsCount(), 0 );
        test.true( !_.process.isAlive( o.pnd.pid ) );
        return null;
      });
    })

    /* */

    .then( () =>
    {
      test.case = 'detaching, child not disconnected, parent waits for child to exit'
      let conTerminate = new _.Consequence();
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        conTerminate,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( result !== o.conStart );
      test.notIdentical( conTerminate, result );
      test.identical( conTerminate, o.conTerminate );

      conTerminate.then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.state, 'terminated' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = 'detached, child disconnected before it termination'
      let conTerminate = new _.Consequence();
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'pipe',
        currentPath : a.routinePath,
        conTerminate,
        detaching : 1
      }
      let track = [];

      let result = _.process.startMinimal( o );
      test.true( result !== o.conStart );
      test.true( result !== o.conTerminate );
      test.identical( conTerminate, o.conTerminate );

      _.time.out( context.t1, () => o.disconnect() );

      conTerminate.then( ( op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( o, op );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return _.time.out( context.t1 * 7, () =>  /* 2000 + context.t2 */ /* 3000 is not enough */
      {
        test.identical( track, [] );
        test.identical( o.state, 'disconnected' );
        test.identical( o.ended, true );
        test.identical( o.conTerminate.argumentsCount(), 0 );
        test.identical( o.conTerminate.errorsCount(), 1 );
        test.identical( o.conTerminate.competitorsCount(), 0 );
        test.true( !_.process.isAlive( o.pnd.pid ) );
        return null;
      });

    })

    /* */

    .then( () =>
    {
      test.case = 'detached, child disconnected after it termination'
      let conTerminate = new _.Consequence();
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        conTerminate,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( result !== o.conStart );
      test.true( result !== o.conTerminate )
      test.identical( conTerminate, o.conTerminate )

      conTerminate.then( ( op ) =>
      {
        test.identical( op.state, 'terminated' );
        test.identical( op.ended, true );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        op.disconnect();
        return op;
      })

      return test.mustNotThrowError( conTerminate )
      .then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.state, 'terminated' );
        test.identical( op.ended, true );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        return null;
      })
    })

    /* */

    .then( () =>
    {
      test.case = 'detached, not disconnected child throws error during execution'
      let conTerminate = new _.Consequence();
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        args : [ 'throwing:1' ],
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        conTerminate,
        throwingExitCode : 0,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( result !== o.conStart );
      test.true( result !== o.conTerminate );
      test.identical( conTerminate, o.conTerminate );

      conTerminate.then( ( op ) =>
      {
        test.identical( o, op );
        test.identical( op.state, 'terminated' );
        test.identical( op.ended, true );
        test.identical( op.error, null );
        test.notIdentical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        return null;
      })

      return conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = 'detached, disconnected child throws error during execution'
      let conTerminate = new _.Consequence();
      let o =
      {
        execPath : mode !== 'fork' ? 'node testAppChild.js' : 'testAppChild.js',
        args : [ 'throwing:1' ],
        mode,
        stdio : 'ignore',
        outputPiping : 0,
        outputCollecting : 0,
        currentPath : a.routinePath,
        conTerminate,
        throwingExitCode : 0,
        detaching : 1
      }
      let track = [];

      let result = _.process.startMinimal( o );

      test.true( result !== o.conStart );
      test.true( result !== o.conTerminate );
      test.identical( conTerminate, o.conTerminate );

      o.disconnect();

      conTerminate.then( () =>
      {
        track.push( 'conTerminate' );
        return null;
      })

      return _.time.out( context.t1 * 7, () =>  /* 2000 + context.t2 */ /* 3000 is not enough */
      {
        test.identical( track, [] );
        test.identical( o.state, 'disconnected' );
        test.identical( o.ended, true );
        test.identical( o.error, null );
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, null );
        test.identical( o.conTerminate.argumentsCount(), 0 );
        test.identical( o.conTerminate.errorsCount(), 1 );
        test.identical( o.conTerminate.competitorsCount(), 0 );
        test.true( !_.process.isAlive( o.pnd.pid ) );
        return null;
      });
    })

    /* */

    return ready;
  }

  /* - */

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var args = _.process.input();

    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      if( args.map.throwing )
      throw _.err( 'Child process error' );
      console.log( 'Child process end' )
      return null;
    })
  }
}

startMinimalOnTerminate.timeOut = 5e5;
startMinimalOnTerminate.rapidity = -1;

//

function startMinimalNoEndBug1( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppChildPath = a.program( testAppChild );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, detaching on, error`;
      let o =
      {
        execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
        mode,
        stdio : [ 'ignore', 'ignore', 'ignore', null ],
        currentPath : a.routinePath,
        detaching : 1
      }

      let result = _.process.startMinimal( o );

      test.true( o.conStart !== result );
      test.true( _.consequenceIs( o.conStart ) )

      result = test.shouldThrowErrorAsync( o.conTerminate );

      result.then( () => _.time.out( context.t1 * 2 ) ) /* 2000 */
      result.then( () =>
      {
        test.identical( o.conTerminate.resourcesCount(), 0 );
        return null;
      })

      return result;
    })

    return ready;

  }

  /* ORIGINAL */
  // a.ready

  // /* */

  // .then( () =>
  // {
  //   test.case = 'detaching on, error on spawn'
  //   let o =
  //   {
  //     execPath : 'testAppChild.js',
  //     mode : 'fork',
  //     stdio : [ 'ignore', 'ignore', 'ignore', null ],
  //     currentPath : a.routinePath,
  //     detaching : 1
  //   }

  //   let result = _.process.start( o );

  //   test.true( o.conStart !== result );
  //   test.true( _.consequenceIs( o.conStart ) )

  //   result = test.shouldThrowErrorAsync( o.conTerminate );

  //   result.then( () => _.time.out( context.t1 * 2 ) ) /* 2000 */
  //   result.then( () =>
  //   {
  //     test.identical( o.conTerminate.resourcesCount(), 0 );
  //     return null;
  //   })

  //   return result;
  // })

  // /* */

  // return a.ready;

  /* */

  function testAppChild()
  {
    _.include( 'wProcess' );
    var args = _.process.input();
    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      console.log( 'Child process end' )
      return null;
    })
  }

}

startMinimalNoEndBug1.timeOut = 1e5; /* Locally : 9.551s */
startMinimalNoEndBug1.description =
`
Parent starts child process in detached mode.
ChildProcess throws an error.
conStart receives error message.
Parent should not try to disconnect the child.
`

//

function startMinimalWithDelayOnReady( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let time1 = _.time.now();

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let con = _.Consequence().take( null );
    con.delay( context.t1 ); /* 1000 */

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      let options =
      {
        execPath : mode === 'fork' ? '' : 'node',
        mode,
        args : programPath,
        currentPath : a.abs( '.' ),
        throwingExitCode : 1,
        applyingExitCode : 0,
        inputMirroring : 1,
        outputCollecting : 1,
        stdio : 'pipe',
        sync : 0,
        deasync : 0,
        ready : con,
      }

      _.process.startMinimal( options );

      test.true( _.consequenceIs( options.conStart ) );
      test.true( _.consequenceIs( options.conDisconnect ) );
      test.true( _.consequenceIs( options.conTerminate ) );
      test.true( _.consequenceIs( options.ready ) );
      test.true( options.conStart !== options.ready );
      test.true( options.conDisconnect !== options.ready );
      test.true( options.conTerminate !== options.ready );

      options.conStart
      .then( ( op ) =>
      {
        test.true( options === op );
        test.identical( options.output, '' );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, null );
        test.identical( options.ended, false );
        test.identical( options.exitReason, null );
        test.true( !!options.pnd );
        return null;
      });

      options.conTerminate
      .finally( ( err, op ) =>
      {
        test.identical( err, undefined );
        debugger;
        test.identical( op.output, 'program1:begin\nprogram1:end\n' );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.ended, true );
        test.identical( op.exitReason, 'normal' );
        return null;
      });

      /* */

      return options.conTerminate;
    })

    return ready;
  }


  /* ORIGINAL */
  // let options =
  // {
  //   execPath : 'node',
  //   args : programPath,
  //   currentPath : a.abs( '.' ),
  //   throwingExitCode : 1,
  //   applyingExitCode : 0,
  //   inputMirroring : 1,
  //   outputCollecting : 1,
  //   stdio : 'pipe',
  //   sync : 0,
  //   deasync : 0,
  //   ready : a.ready,
  // }

  // _.process.start( options );

  // test.true( _.consequenceIs( options.conStart ) );
  // test.true( _.consequenceIs( options.conDisconnect ) );
  // test.true( _.consequenceIs( options.conTerminate ) );
  // test.true( _.consequenceIs( options.ready ) );
  // test.true( options.conStart !== options.ready );
  // test.true( options.conDisconnect !== options.ready );
  // test.true( options.conTerminate !== options.ready );

  // options.conStart
  // .then( ( op ) =>
  // {
  //   test.true( options === op );
  //   test.identical( options.output, '' );
  //   test.identical( options.exitCode, null );
  //   test.identical( options.exitSignal, null );
  //   test.identical( options.pnd.exitCode, null );
  //   test.identical( options.pnd.signalCode, null );
  //   test.identical( options.ended, false );
  //   test.identical( options.exitReason, null );
  //   test.true( !!options.pnd );
  //   return null;
  // });

  // options.conTerminate
  // .finally( ( err, op ) =>
  // {
  //   test.identical( err, undefined );
  //   debugger;
  //   test.identical( op.output, 'program1:begin\nprogram1:end\n' );
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.exitSignal, null );
  //   test.identical( op.ended, true );
  //   test.identical( op.exitReason, 'normal' );
  //   return null;
  // });

  // /* */

  // return a.ready;

  /* */

  function program1()
  {
    let _ = require( toolsPath );
    console.log( 'program1:begin' );
    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 15 ); /* 15000 */
  }

}

startMinimalWithDelayOnReady.timeOut = 52e4; /* Locally : 51.614s */
startMinimalWithDelayOnReady.description =
`
  - consequence conStart has delay
`

//

function startMinimalOnIsNotConsequence( test )
{
  let context = this;
  let track;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  // let modes = [ 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 0, 1, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 0, mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run( 1, 1, mode ) ) );
  return a.ready;

  /* - */

  function run( sync, deasync, mode )
  {
    let con = _.Consequence().take( null );

    if( sync && !deasync && mode === 'fork' )
    return null;

    /* */

    con.then( () =>
    {
      test.case = `normal sync:${sync} deasync:${deasync} mode:${mode}`
      track = [];
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        mode,
        sync,
        deasync,
        conStart,
        conDisconnect,
        conTerminate,
        ready,
      }
      var returned = _.process.startMinimal( o );
      o.ready.finally( function( err, op )
      {
        track.push( 'returned' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        return op;
      })

      return _.time.out( context.t2, () =>
      {
        test.identical( track, [ 'conStart', 'conTerminate', 'conDisconnect', 'ready', 'returned' ] );
      });
    })

    /* */

    con.then( () =>
    {
      test.case = `throwing sync:${sync} deasync:${deasync} mode:${mode}`
      track = [];
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        args : [ 'throwing' ],
        mode,
        conStart,
        conDisconnect,
        conTerminate,
        ready,
      }
      var returned = _.process.startMinimal( o );
      o.ready.finally( function( err, op )
      {
        track.push( 'returned' );
        test.true( _.errIs( err ) );
        test.identical( op, undefined );
        test.notIdentical( o.exitCode, 0 );
        test.identical( o.ended, true );
        _.errAttend( err );
        return null;
      })
      return _.time.out( context.t2, () =>
      {
        test.identical( track, [ 'conStart', 'conTerminate', 'conDisconnect', 'ready', 'returned' ] );
      });
    })

    /* */

    con.then( () =>
    {
      test.case = `detaching sync:${sync} deasync:${deasync} mode:${mode}`
      track = [];
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        detaching : 1,
        mode,
        conStart,
        conDisconnect,
        conTerminate,
        ready,
      }
      var returned = _.process.startMinimal( o );
      o.ready.finally( function( err, op )
      {
        track.push( 'returned' );
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        return op;
      })

      return _.time.out( context.t2, () =>
      {
        test.identical( track, [ 'conStart', 'conTerminate', 'conDisconnect', 'ready', 'returned' ] );
      });
    })

    /* */

    con.then( () =>
    {
      test.case = `disconnecting sync:${sync} deasync:${deasync} mode:${mode}`
      track = [];
      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        detaching : 1,
        mode,
        conStart,
        conDisconnect,
        conTerminate,
        ready,
      }
      var returned = _.process.startMinimal( o );
      o.disconnect();
      o.ready.finally( function( err, op )
      {
        track.push( 'returned' );
        test.identical( op.exitCode, null );
        test.identical( op.ended, true );
        return op;
      })

      return _.time.out( context.t2, () =>
      {
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate', 'ready', 'returned' ] );
      });
    })

    /* */

    return con
  }

  function program1()
  {
    console.log( process.argv.slice( 2 ) );
    if( process.argv.slice( 2 ).join( ' ' ).includes( 'throwing' ) )
    throw 'Error1!'
  }

  function ready( err, arg )
  {
    track.push( 'ready' );
    if( err )
    throw err;
    return arg;
  }

  function conStart( err, arg )
  {
    track.push( 'conStart' );
    if( err )
    throw err;
    return arg;
  }

  function conTerminate( err, arg )
  {
    track.push( 'conTerminate' );
    if( err )
    throw err;
    return arg;
  }

  function conDisconnect( err, arg )
  {
    track.push( 'conDisconnect' );
    if( err )
    throw err;
    return arg;
  }

}

startMinimalOnIsNotConsequence.rapidity = -1;
startMinimalOnIsNotConsequence.timeOut = 5e5;

//

function startMultipleConcurrent( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let time = 0;
  let filePath = a.path.nativize( a.abs( a.routinePath, 'file.txt' ) );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let counter = 0;

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single`;
      time = _.time.now();

      let singleOption =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      return _.process.startSingle( singleOption )
      .then( ( arg ) =>
      {

        test.identical( arg.exitCode, 0 );
        test.true( singleOption === arg );
        test.true( _.strHas( arg.output, 'begin 1000' ) );
        test.true( _.strHas( arg.output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, execPath in array`;
      time = _.time.now();

      let singleExecPathInArrayOptions =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000' ] : [ 'node ' + testAppPath + ' 1000' ],
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      return _.process.startMultiple( singleExecPathInArrayOptions )
      .then( ( op ) =>
      {

        test.identical( op.sessions.length, 1 );
        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( singleExecPathInArrayOptions !== op.sessions[ 0 ] );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, error in ready`;

      let con = _.Consequence().take( null );
      con.then( () =>
      {
        time = _.time.now();
        throw _.err( 'Error!' );
      })

      let singleErrorBeforeScalar =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        ready : con,
        verbosity : 3,
        outputCollecting : 1,
      }

      return _.process.startSingle( singleErrorBeforeScalar )
      .finally( ( err, arg ) =>
      {
        test.true( arg === undefined );
        test.true( _.errIs( err ) );
        test.identical( singleErrorBeforeScalar.exitCode, null );
        test.identical( singleErrorBeforeScalar.output, '' );
        test.true( !a.fileProvider.fileExists( filePath ) );
        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, array execPath, error in ready`;

      let con = _.Consequence().take( null );
      con.then( () =>
      {
        time = _.time.now();
        throw _.err( 'Error!' );
      })

      let singleErrorBefore =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000' ] : [ 'node ' + testAppPath + ' 1000' ],
        mode,
        ready : con,
        verbosity : 3,
        outputCollecting : 1,
      }

      return _.process.startMultiple( singleErrorBefore )
      .finally( ( err, arg ) =>
      {
        test.true( arg === undefined );
        test.true( _.errIs( err ) );
        test.identical( singleErrorBefore.exitCode, null );
        test.identical( singleErrorBefore.output, '' );
        test.true( !a.fileProvider.fileExists( filePath ) );
        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial`;
      time = _.time.now();

      let subprocessesOptionsSerial =
      {
        execPath : mode === 'fork' ? [  testAppPath + ' 1000', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
      }

      return _.process.startMultiple( subprocessesOptionsSerial )
      .then( ( op ) =>
      {

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesOptionsSerial.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial, error, throwingExitCode : 1`;
      time = _.time.now();

      let subprocessesError =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
      }

      return _.process.startMultiple( subprocessesError )
      .finally( ( err, op ) =>
      {

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesError.exitCode, 1 );
        test.true( _.errIs( err ) );
        test.true( op === undefined );
        test.true( !a.fileProvider.fileExists( filePath ) );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial, error, throwingExitCode : 0`;
      time = _.time.now();

      let subprocessesErrorNonThrowing =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
        throwingExitCode : 0,
      }

      return _.process.startMultiple( subprocessesErrorNonThrowing )
      .finally( ( err, op ) =>
      {
        test.true( !err );

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorNonThrowing.exitCode, 1 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 1 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
        test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1, error, throwingExitCode : 1`;
      time = _.time.now();

      let subprocessesErrorConcurrent =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      return _.process.startMultiple( subprocessesErrorConcurrent )
      .finally( ( err, op ) =>
      {

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorConcurrent.exitCode, 1 );
        test.true( _.errIs( err ) );
        test.true( op === undefined );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1, error, throwingExitCode : 0`;
      time = _.time.now();

      let subprocessesErrorConcurrentNonThrowing =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
        throwingExitCode : 0,
      }

      return _.process.startMultiple( subprocessesErrorConcurrentNonThrowing )
      .finally( ( err, op ) =>
      {
        test.true( !err );

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorConcurrentNonThrowing.exitCode, 1 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 1 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
        test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1`;
      time = _.time.now();

      let suprocessesConcurrentOptions =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000', testAppPath + ' 100' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      return _.process.startMultiple( suprocessesConcurrentOptions )
      .then( ( op ) =>
      {

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent )
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( suprocessesConcurrentOptions.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 100' ) );

        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, args`;
      time = _.time.now();

      let suprocessesConcurrentArgumentsOptions =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000', testAppPath + ' 100' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
        args : [ 'second', 'argument' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      return _.process.startMultiple( suprocessesConcurrentArgumentsOptions )
      .then( ( op ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent )
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( suprocessesConcurrentArgumentsOptions.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000, second, argument' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000, second, argument' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100, second, argument' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 100, second, argument' ) );

        counter += 1;
        return null;
      });
    });

    /* */

    return ready.finally( ( err, arg ) =>
    {
      test.identical( counter, 11 );
      if( err )
      throw err;
      return arg;
    });
  }

  /* ORIGINAL */
  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleOption =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // _.process.start( singleOption )
  // .then( ( arg ) =>
  // {

  //   test.identical( arg.exitCode, 0 );
  //   test.true( singleOption === arg );
  //   test.true( _.strHas( arg.output, 'begin 1000' ) );
  //   test.true( _.strHas( arg.output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, execPath in array';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleExecPathInArrayOptions =
  // {
  //   execPath : [ 'node ' + testAppPath + ' 1000' ],
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // _.process.start( singleExecPathInArrayOptions )
  // .then( ( op ) =>
  // {

  //   test.identical( op.sessions.length, 1 );
  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( singleExecPathInArrayOptions !== op.sessions[ 0 ] );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, error in ready';
  //   time = _.time.now();
  //   throw _.err( 'Error!' );
  // })

  // let singleErrorBeforeScalar =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // _.process.start( singleErrorBeforeScalar )
  // .finally( ( err, arg ) =>
  // {
  //   test.true( arg === undefined );
  //   test.true( _.errIs( err ) );
  //   test.identical( singleErrorBeforeScalar.exitCode, null );
  //   test.identical( singleErrorBeforeScalar.output, '' );
  //   test.true( !a.fileProvider.fileExists( filePath ) );
  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, error in ready';
  //   time = _.time.now();
  //   throw _.err( 'Error!' );
  // })

  // let singleErrorBefore =
  // {
  //   execPath : [ 'node ' + testAppPath + ' 1000' ],
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // _.process.start( singleErrorBefore )
  // .finally( ( err, arg ) =>
  // {

  //   test.true( arg === undefined );
  //   test.true( _.errIs( err ) );
  //   test.identical( singleErrorBefore.exitCode, null );
  //   test.identical( singleErrorBefore.output, '' );
  //   test.true( !a.fileProvider.fileExists( filePath ) );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesOptionsSerial =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  // }

  // _.process.start( subprocessesOptionsSerial )
  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesOptionsSerial.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial, error, throwingExitCode : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesError =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  // }

  // _.process.start( subprocessesError )
  // .finally( ( err, op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesError.exitCode, 1 );
  //   test.true( _.errIs( err ) );
  //   test.true( op === undefined );
  //   test.true( !a.fileProvider.fileExists( filePath ) );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial, error, throwingExitCode : 0';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorNonThrowing =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  //   throwingExitCode : 0,
  // }

  // _.process.start( subprocessesErrorNonThrowing )
  // .finally( ( err, op ) =>
  // {
  //   test.true( !err );

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorNonThrowing.exitCode, 1 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 1 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
  //   test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1, error, throwingExitCode : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorConcurrent =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // _.process.start( subprocessesErrorConcurrent )
  // .finally( ( err, op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorConcurrent.exitCode, 1 );
  //   test.true( _.errIs( err ) );
  //   test.true( op === undefined );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1, error, throwingExitCode : 0';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorConcurrentNonThrowing =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  //   throwingExitCode : 0,
  // }

  // _.process.start( subprocessesErrorConcurrentNonThrowing )
  // .finally( ( err, op ) =>
  // {
  //   test.true( !err );

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorConcurrentNonThrowing.exitCode, 1 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 1 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
  //   test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let suprocessesConcurrentOptions =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // _.process.start( suprocessesConcurrentOptions )
  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent )
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( suprocessesConcurrentOptions.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 100' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'args';
  //   time = _.time.now();
  //   return null;
  // })

  // let suprocessesConcurrentArgumentsOptions =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
  //   args : [ 'second', 'argument' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // _.process.start( suprocessesConcurrentArgumentsOptions )
  // .then( ( op ) =>
  // {
  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent )
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( suprocessesConcurrentArgumentsOptions.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000, second, argument' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000, second, argument' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100, second, argument' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 100, second, argument' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // return a.ready.finally( ( err, arg ) =>
  // {
  //   test.identical( counter, 11 );
  //   if( err )
  //   throw err;
  //   return arg;
  // });

  /* - */

  function program1()
  {
    var ended = 0;
    var fs = require( 'fs' );
    var path = require( 'path' );
    var filePath = path.join( __dirname, 'file.txt' );
    console.log( 'begin', process.argv.slice( 2 ).join( ', ' ) );
    var time = parseInt( process.argv[ 2 ] );
    if( isNaN( time ) )
    throw new Error( 'Expects number' );

    setTimeout( end, time );
    function end()
    {
      ended = 1;
      fs.writeFileSync( filePath, 'written by ' + process.argv[ 2 ] );
      console.log( 'end', process.argv.slice( 2 ).join( ', ' ) );
    }

    setTimeout( periodic, context.t1 / 20 ); /* 50 */
    function periodic()
    {
      console.log( 'tick', process.argv.slice( 2 ).join( ', ' ) );
      if( !ended )
      setTimeout( periodic, context.t1 / 20 ); /* 50 */
    }
  }

}

startMultipleConcurrent.timeOut = 23e4; /* Locally : 22.686s */

//

function startMultipleConcurrentConsequences( test )
{
  let context = this;
  let track;
  let track2;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let t0 = _.time.now();
  let o3 =
  {
    outputPiping : 1,
    outputCollecting : 1,
  }

  let consequences = [ 'null', 'consequence', 'routine' ];
  let modes = [ 'fork', 'spawn', 'shell' ];
  consequences.forEach( ( consequence ) =>
  {
    a.ready.tap( () => test.open( `consequence:${consequence}` ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, consequence, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, consequence, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, consequence, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, consequence, mode }) ) );
    a.ready.tap( () => test.close( `consequence:${consequence}` ) );
  });
  return a.ready;

  /* - */

  function run( tops )
  {
    let ready = _.Consequence().take( null );
    if( tops.mode === 'fork' && tops.sync && !tops.deasync )
    return null;

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:0 arg arg`;

      clear();
      var time1 = _.time.now();
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id}` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 0,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.tap( function( err, op )
      {
        var exp =
`
${options.sessions[ 0 ].procedure.id}.begin
${options.sessions[ 0 ].procedure.id}.end
${options.sessions[ 1 ].procedure.id}.begin
${options.sessions[ 1 ].procedure.id}.end
`
        test.equivalent( options.output, exp );

        var exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
          `${options.procedure.id}.conTerminate`,
          `${options.procedure.id}.ready`,
        ]
        if( options.deasync || options.sync )
        exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.procedure.id}.conTerminate`,
          `${options.procedure.id}.ready`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
        ]
        test.identical( track, exp );

        var exp =
        [
          'conStart.arg',
          'conTerminate.arg',
          'ready.arg',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.identical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'normal' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );

        test.identical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'normal' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.identical( options.error, null );

        test.identical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'normal' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'terminated' );
        test.identical( options.error, null );

      })

      return options.ready;
    })

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:0 throwingExitCode:1 err arg`;

      clear();
      var time1 = _.time.now();
      var counter = 0;
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id} throwing:${++counter === 1 ? 1 : 0}` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 0,
        throwingExitCode : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = null;

      if( tops.sync )
      test.shouldThrowErrorSync( () => _.process.startMultiple( options ) );
      else
      returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.finally( function( err, op )
      {
        test.identical( _.strCount( options.output, 'Error1' ), 1 );
        var exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 1 ].procedure.id}.conStart.err`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 1 ].procedure.id}.ready.err`,
          `${options.sessions[ 0 ].procedure.id}.ready.err`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
        ]
        if( options.deasync || options.sync )
        exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 0 ].procedure.id}.ready.err`,
          `${options.sessions[ 1 ].procedure.id}.conStart.err`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 1 ].procedure.id}.ready.err`,
        ]

        test.identical( track, exp );

        var exp =
        [
          'conStart.arg',
          'conTerminate.err',
          'ready.err',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.true( _.errIs( err ) );
        test.notIdentical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'code' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.true( !!options.error );
        test.identical( _.strCount( options.error.message, 'Error1' ), 1 );

        test.notIdentical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'code' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.true( !!options.sessions[ 0 ].error );

        test.notIdentical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'error' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'initial' );
        test.true( !!options.sessions[ 1 ].error );

        return null;
      })

      return options.ready;
    })

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:0 throwingExitCode:1 arg err`;

      clear();
      var time1 = _.time.now();
      var counter = 0;
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id} throwing:${++counter === 1 ? 0 : 1}` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 0,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = null;

      if( tops.sync )
      test.shouldThrowErrorSync( () => _.process.startMultiple( options ) );
      else
      returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.finally( function( err, op )
      {

        test.identical( _.strCount( options.output, 'Error1' ), 1 );
        var exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 1 ].procedure.id}.ready.err`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
        ]
        if( options.deasync || options.sync )
        exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 1 ].procedure.id}.ready.err`,
        ]
        test.identical( track, exp );

        var exp =
        [
          'conStart.arg',
          'conTerminate.err',
          'ready.err',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.true( _.errIs( err ) );
        test.notIdentical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'code' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.true( !!options.error );
        test.identical( _.strCount( options.error.message, 'Error1' ), 1 );

        test.identical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'normal' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.true( !options.sessions[ 0 ].error );

        test.notIdentical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'code' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'terminated' );
        test.true( !!options.sessions[ 1 ].error );

        return null;
      })

      return options.ready;
    })

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:1 arg arg`;

      if( tops.sync && !tops.deasync )
      return null;

      clear();
      var time1 = _.time.now();
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id}`, `sessionId:${op.sessionId}`, `concurrent:1` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.tap( function( err, op )
      {
        var exp =
`
${options.sessions[ 0 ].procedure.id}.begin
${options.sessions[ 1 ].procedure.id}.begin
${options.sessions[ 0 ].procedure.id}.end
${options.sessions[ 1 ].procedure.id}.end
`

        test.equivalent( options.output, exp );
        var exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
          `${options.procedure.id}.conTerminate`,
          `${options.procedure.id}.ready`,
        ]
        if( options.deasync || options.sync )
        exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.procedure.id}.conTerminate`,
          `${options.procedure.id}.ready`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 0 ].procedure.id}.ready`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
        ]
        test.identical( track, exp );

        var exp =
        [
          'conStart.arg',
          'conTerminate.arg',
          'ready.arg',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.identical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'normal' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );

        test.identical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'normal' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.identical( options.error, null );

        test.identical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'normal' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'terminated' );
        test.identical( options.error, null );

      })

      return options.ready;
    })

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:1 throwingExitCode:1 err arg`;

      if( tops.sync && !tops.deasync )
      return null;

      clear();
      var time1 = _.time.now();
      var counter = 0;
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id}`, `throwing:${++counter === 1 ? 1 : 0}`, `sessionId:${op.sessionId}`, `concurrent:1` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 1,
        throwingExitCode : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = null;

      if( tops.sync )
      test.shouldThrowErrorSync( () => _.process.startMultiple( options ) );
      else
      returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.finally( function( err, op )
      {
        test.identical( _.strCount( options.output, 'Error1' ), 1 );
        var exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 0 ].procedure.id}.ready.err`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
        ]
        if( options.deasync || options.sync )
        exp =
        [
          `${options.procedure.id}.conStart`,
          `${options.procedure.id}.conTerminate.err`,
          `${options.procedure.id}.ready.err`,
          `${options.sessions[ 0 ].procedure.id}.conStart`,
          `${options.sessions[ 0 ].procedure.id}.conTerminate.err`,
          `${options.sessions[ 0 ].procedure.id}.conDisconnect.err`,
          `${options.sessions[ 0 ].procedure.id}.ready.err`,
          `${options.sessions[ 1 ].procedure.id}.conStart`,
          `${options.sessions[ 1 ].procedure.id}.conTerminate`,
          `${options.sessions[ 1 ].procedure.id}.conDisconnect.dont`,
          `${options.sessions[ 1 ].procedure.id}.ready`,
        ]

        test.identical( track, exp );

        var exp =
        [
          'conStart.arg',
          'conTerminate.err',
          'ready.err',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.notIdentical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'code' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.true( !!options.error );
        test.identical( _.strCount( options.error.message, 'Error1' ), 1 );

        test.notIdentical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'code' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.true( !!options.sessions[ 0 ].error );

        test.identical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'normal' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'terminated' );
        test.true( !options.sessions[ 1 ].error );

        return null;
      })

      return options.ready;
    })

    /* */

    ready.then( function( arg )
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:1 throwingExitCode:1 arg err`;

      if( tops.sync && !tops.deasync )
      return null;

      clear();
      var time1 = _.time.now();
      var counter = 0;
      var execPath = tops.mode === `fork` ? `${programPath}` : `node ${programPath}`;
      var o2 =
      {
        execPath : [ execPath, execPath ],
        args : ( op ) => [ `id:${op.procedure.id} throwing:${++counter === 1 ? 0 : 1}` ],
        conStart : conMake( tops, 'conStart' ),
        conDisconnect : conMake( tops, 'conDisconnect' ),
        conTerminate : conMake( tops, 'conTerminate' ),
        ready : conMake( tops, 'ready' ),
        concurrent : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        mode : tops.mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = null;

      if( tops.sync )
      test.shouldThrowErrorSync( () => _.process.startMultiple( options ) );
      else
      returned = _.process.startMultiple( options );

      processTrack( options );

      options.conStart.tap( ( err, op ) =>
      {
        op.sessions.forEach( ( op2 ) =>
        {
          processTrack( op2 );
        });
      });

      options.ready.finally( function( err, op )
      {

        test.identical( _.strCount( options.output, 'Error1' ), 1 );

        if( options.deasync || options.sync )
        {
          var exp =
          [
            `${options.procedure.id}.conStart`,
            `${options.procedure.id}.conTerminate.err`,
            `${options.procedure.id}.ready.err`,
            `${options.sessions[ 0 ].procedure.id}.conStart`,
            `${options.sessions[ 0 ].procedure.id}.conTerminate`,
            `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
            `${options.sessions[ 0 ].procedure.id}.ready`,
            `${options.sessions[ 1 ].procedure.id}.conStart`,
            `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
            `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
            `${options.sessions[ 1 ].procedure.id}.ready.err`,
          ]
          test.identical( track, exp );
        }
        else
        {
          var exp =
          [
            `${options.procedure.id}.conStart`,
            `${options.sessions[ 0 ].procedure.id}.conStart`,
            `${options.sessions[ 1 ].procedure.id}.conStart`,
            `${options.sessions[ 0 ].procedure.id}.conTerminate`,
            `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
            `${options.sessions[ 0 ].procedure.id}.ready`,
            `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
            `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
            `${options.sessions[ 1 ].procedure.id}.ready.err`,
            `${options.procedure.id}.conTerminate.err`,
            `${options.procedure.id}.ready.err`,
          ]
          /*
          the first children can be terminatead before the second, but also can after
          */
          if( !_.identical( track, exp ) )
          exp =
          [
            `${options.procedure.id}.conStart`,
            `${options.sessions[ 0 ].procedure.id}.conStart`,
            `${options.sessions[ 1 ].procedure.id}.conStart`,
            `${options.sessions[ 1 ].procedure.id}.conTerminate.err`,
            `${options.sessions[ 1 ].procedure.id}.conDisconnect.err`,
            `${options.sessions[ 1 ].procedure.id}.ready.err`,
            `${options.sessions[ 0 ].procedure.id}.conTerminate`,
            `${options.sessions[ 0 ].procedure.id}.conDisconnect.dont`,
            `${options.sessions[ 0 ].procedure.id}.ready`,
            `${options.procedure.id}.conTerminate.err`,
            `${options.procedure.id}.ready.err`,
          ]
          test.identical( track, exp );
        }

        var exp =
        [
          'conStart.arg',
          'conTerminate.err',
          'ready.err',
        ]
        if( tops.consequence === 'routine' )
        test.identical( track2, exp );

        test.true( _.errIs( err ) );
        test.notIdentical( options.exitCode, 0 );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'code' );
        test.identical( options.exitSignal, null );
        test.identical( options.state, 'terminated' );
        test.true( !!options.error );
        test.identical( _.strCount( options.error.message, 'Error1' ), 1 );

        test.identical( options.sessions[ 0 ].exitCode, 0 );
        test.identical( options.sessions[ 0 ].ended, true );
        test.identical( options.sessions[ 0 ].exitReason, 'normal' );
        test.identical( options.sessions[ 0 ].exitSignal, null );
        test.identical( options.sessions[ 0 ].state, 'terminated' );
        test.true( !options.sessions[ 0 ].error );

        test.notIdentical( options.sessions[ 1 ].exitCode, 0 );
        test.identical( options.sessions[ 1 ].ended, true );
        test.identical( options.sessions[ 1 ].exitReason, 'code' );
        test.identical( options.sessions[ 1 ].exitSignal, null );
        test.identical( options.sessions[ 1 ].state, 'terminated' );
        test.true( !!options.sessions[ 1 ].error );

        return null;
      })

      return options.ready;
    })

    /* */

    return ready;
  }

  /* - */

  function conMake( tops, name )
  {

    if( name === 'conDisconnect' )
    return null;

    if( tops.consequence === 'consequence' )
    {
      if( name === 'ready' )
      return new _.Consequence().take( null );
      else
      return new _.Consequence();
    }
    else if( tops.consequence === 'null' )
    {
      return null;
    }
    else if( tops.consequence === 'routine' )
    {
      return routine;
    }
    else _.assert( 0, `Unknown ${tops.consequence}` );
    function routine( err, arg )
    {
      if( err )
      track2.push( name + ( _.symbolIs( err ) ? '.dont' : '.err' ) );
      else
      track2.push( name + '.arg' );
      if( err )
      throw err;
      return arg;
    }
  }

  function clear()
  {
    track = [];
    track2 = [];
  }

  function processTrack( op )
  {
    consequenceTrack( op, 'conStart' );
    consequenceTrack( op, 'conTerminate' );
    consequenceTrack( op, 'conDisconnect' );
    consequenceTrack( op, 'ready' );
  }

  function consequenceTrack( op, cname )
  {
    if( _.consequenceIs( op[ cname ] ) )
    op[ cname ].tap( ( err, op2 ) =>
    {
      eventTrack( op, cname, err );
    });
  }

  function eventTrack( op, name, err )
  {
    _.assert( !!op.procedure );
    let postfix = '';
    if( err )
    postfix = _.symbolIs( err ) ? '.dont' : '.err';
    track.push( `${op.procedure.id}.${name}${postfix}` );
    /* track.push( `${op.procedure.id}.${name}${err ? '.err' : ''} - ${_.time.now() - t0}` ); */
    if( err )
    _.errAttend( err );
  }

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    let args = _.process.input();

    let sessionDelay = context.t1 * 0.5*args.map.sessionId;

    if( args.map.concurrent )
    setTimeout( () => { console.log( `${args.map.id}.begin` ) }, sessionDelay );
    else
    console.log( `${args.map.id}.begin` );
    setTimeout( () => { console.log( `${args.map.id}.end` ) }, context.t1 + sessionDelay );

    if( args.map.throwing )
    throw 'Error1';

  }

}

startMultipleConcurrentConsequences.rapidity = -1;
startMultipleConcurrentConsequences.timeOut = 1e8;
startMultipleConcurrentConsequences.description =
`
  - all consequences are called
  - consequences are called in correct order
`

//

function starterConcurrentMultiple( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let time = 0;
  let filePath = a.path.nativize( a.abs( a.routinePath, 'file.txt' ) );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let counter = 0;

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single`;
      time = _.time.now();

      let singleOption2 = {}
      let singleOption =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      var start = _.process.starter( singleOption );

      return start( singleOption2 )
      .then( ( arg ) =>
      {
        test.identical( arg.exitCode, 0 );
        test.true( singleOption !== arg );
        test.true( singleOption2 === arg );
        test.true( _.strHas( arg.output, 'begin 1000' ) );
        test.true( _.strHas( arg.output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, no second options`;
      time = _.time.now();

      let singleOptionWithoutSecond =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      var start = _.process.starter( singleOptionWithoutSecond );
      return start()
      .then( ( arg ) =>
      {
        test.identical( arg.exitCode, 0 );
        test.true( singleOptionWithoutSecond !== arg );
        test.true( _.strHas( arg.output, 'begin 1000' ) );
        test.true( _.strHas( arg.output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, execPath in array`;
      time = _.time.now();

      let singleExecPathInArrayOptions2 = {};
      let singleExecPathInArrayOptions =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        verbosity : 3,
        outputCollecting : 1,
      }

      var start = _.process.starter( singleExecPathInArrayOptions );
      return start( singleExecPathInArrayOptions2 )
      .then( ( arg ) =>
      {
        test.identical( arg.exitCode, 0 );
        test.true( singleExecPathInArrayOptions2 === arg );
        test.true( _.strHas( arg.output, 'begin 1000' ) );
        test.true( _.strHas( arg.output, 'end 1000' ) );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );
        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, error in ready, exec is scalar`;
      let con = _.Consequence().take( null );

      con.then( () =>
      {
        time = _.time.now();
        throw _.err( 'Error!' );
      })

      let singleErrorBeforeScalar2 = {};
      let singleErrorBeforeScalar =
      {
        execPath : mode === 'fork' ? testAppPath + ' 1000' : 'node ' + testAppPath + ' 1000',
        mode,
        ready : con,
        verbosity : 3,
        outputCollecting : 1,
      }

      var start = _.process.starter( singleErrorBeforeScalar );
      return start( singleErrorBeforeScalar2 )
      .finally( ( err, arg ) =>
      {
        test.true( arg === undefined );
        test.true( _.errIs( err ) );
        test.identical( singleErrorBeforeScalar.exitCode, undefined );
        test.identical( singleErrorBeforeScalar.output, undefined );
        test.true( !a.fileProvider.fileExists( filePath ) );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, single, error in ready, exec is single-element vector`;
      let con = _.Consequence().take( null );

      con.then( () =>
      {
        time = _.time.now();
        throw _.err( 'Error!' );
      })

      let singleErrorBefore2 = {};
      let singleErrorBefore =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000' ] : [ 'node ' + testAppPath + ' 1000' ],
        mode,
        ready : con,
        verbosity : 3,
        outputCollecting : 1,
      }

      var start = _.process.starter( singleErrorBefore );
      return start( singleErrorBefore2 )
      .finally( ( err, arg ) =>
      {
        test.true( arg === undefined );
        test.true( _.errIs( err ) );
        test.identical( singleErrorBefore.exitCode, undefined );
        test.identical( singleErrorBefore.output, undefined );
        test.true( !a.fileProvider.fileExists( filePath ) );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial`;
      time = _.time.now();

      let subprocessesOptionsSerial2 = {};
      let subprocessesOptionsSerial =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
      }

      var start = _.process.starter( subprocessesOptionsSerial );
      return start( subprocessesOptionsSerial2 )
      .then( ( op ) =>
      {

        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesOptionsSerial2.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial, error, throwingExitCode : 1`;
      time = _.time.now();

      let subprocessesError2 = {};
      let subprocessesError =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
      }

      var start = _.process.starter( subprocessesError );
      return start( subprocessesError2 )
      .finally( ( err, arg ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesError2.exitCode, 1 );
        test.true( _.errIs( err ) );
        test.true( arg === undefined );
        test.true( !a.fileProvider.fileExists( filePath ) );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, serial, error, throwingExitCode : 0`;
      time = _.time.now();

      let subprocessesErrorNonThrowing2 = {};
      let subprocessesErrorNonThrowing =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 0,
        throwingExitCode : 0,
      }

      var start = _.process.starter( subprocessesErrorNonThrowing );
      return start( subprocessesErrorNonThrowing2 )
      .then( ( op ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorNonThrowing2.exitCode, 1 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 1 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
        test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    })

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1, error, throwingExitCode : 1`;
      time = _.time.now();

      let subprocessesErrorConcurrent2 = {};
      let subprocessesErrorConcurrent =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      var start = _.process.starter( subprocessesErrorConcurrent );
      return start( subprocessesErrorConcurrent2 )
      .finally( ( err, arg ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorConcurrent2.exitCode, 1 );
        test.true( _.errIs( err ) );
        test.true( arg === undefined );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        _.errAttend( err );
        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1, error, throwingExitCode : 0`;
      time = _.time.now();

      let subprocessesErrorConcurrentNonThrowing2 = {};
      let subprocessesErrorConcurrentNonThrowing =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' x', testAppPath + ' 1' ] : [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
        throwingExitCode : 0,
      }

      var start = _.process.starter( subprocessesErrorConcurrentNonThrowing );
      return start( subprocessesErrorConcurrentNonThrowing2 )
      .then( ( op ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent );
        test.gt( spent, 0 );
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesErrorConcurrentNonThrowing2.exitCode, 1 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 1 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
        test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, subprocesses, concurrent : 1`;
      time = _.time.now();

      let subprocessesConcurrentOptions2 = {};
      let subprocessesConcurrentOptions =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000', testAppPath + ' 100' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      var start = _.process.starter( subprocessesConcurrentOptions );
      return start( subprocessesConcurrentOptions2 )
      .then( ( op ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent )
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesConcurrentOptions2.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 100' ) );

        counter += 1;
        return null;
      });
    });

    /* */

    ready.then( ( arg ) =>
    {
      test.case = `mode : ${mode}, args`;
      time = _.time.now();

      let subprocessesConcurrentArgumentsOptions2 = {}
      let subprocessesConcurrentArgumentsOptions =
      {
        execPath : mode === 'fork' ? [ testAppPath + ' 1000', testAppPath + ' 100' ] : [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
        args : [ 'second', 'argument' ],
        mode,
        outputCollecting : 1,
        verbosity : 3,
        concurrent : 1,
      }

      var start = _.process.starter( subprocessesConcurrentArgumentsOptions );
      return start( subprocessesConcurrentArgumentsOptions2 )
      .then( ( op ) =>
      {
        var spent = _.time.now() - time;
        logger.log( 'Spent', spent )
        test.gt( spent, context.t1 ); /* 1000 */
        test.le( spent, context.t1 * 5 ); /* 5000 */

        test.identical( subprocessesConcurrentArgumentsOptions2.exitCode, 0 );
        test.identical( op.sessions.length, 2 );
        test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
        a.fileProvider.fileDelete( filePath );

        test.identical( op.sessions[ 0 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000, second, argument' ) );
        test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000, second, argument' ) );

        test.identical( op.sessions[ 1 ].exitCode, 0 );
        test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100, second, argument' ) );
        test.true( _.strHas( op.sessions[ 1 ].output, 'end 100, second, argument' ) );

        counter += 1;
        return null;
      });
    })

    /* */

    return ready.finally( ( err, arg ) =>
    {
      debugger;
      test.identical( counter, 12 );
      if( err )
      throw err;
      return arg;
    });

    return ready;
  }

  /* ORIGINAL */
  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleOption2 = {}
  // let singleOption =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // var start = _.process.starter( singleOption );
  // start( singleOption2 )

  // .then( ( arg ) =>
  // {
  //   test.identical( arg.exitCode, 0 );
  //   test.true( singleOption !== arg );
  //   test.true( singleOption2 === arg );
  //   test.true( _.strHas( arg.output, 'begin 1000' ) );
  //   test.true( _.strHas( arg.output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, no second options';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleOptionWithoutSecond =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // var start = _.process.starter( singleOptionWithoutSecond );
  // start()

  // .then( ( arg ) =>
  // {

  //   test.identical( arg.exitCode, 0 );
  //   test.true( singleOptionWithoutSecond !== arg );
  //   test.true( _.strHas( arg.output, 'begin 1000' ) );
  //   test.true( _.strHas( arg.output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, execPath in array';
  //   time = _.time.now();
  //   return null;
  // })

  // let singleExecPathInArrayOptions2 = {};
  // let singleExecPathInArrayOptions =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // var start = _.process.starter( singleExecPathInArrayOptions );
  // start( singleExecPathInArrayOptions2 )

  // .then( ( arg ) =>
  // {
  //   test.identical( arg.exitCode, 0 );
  //   test.true( singleExecPathInArrayOptions2 === arg );
  //   test.true( _.strHas( arg.output, 'begin 1000' ) );
  //   test.true( _.strHas( arg.output, 'end 1000' ) );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, error in ready, exec is scalar';
  //   time = _.time.now();
  //   throw _.err( 'Error!' );
  // })

  // let singleErrorBeforeScalar2 = {};
  // let singleErrorBeforeScalar =
  // {
  //   execPath : 'node ' + testAppPath + ' 1000',
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // var start = _.process.starter( singleErrorBeforeScalar );
  // start( singleErrorBeforeScalar2 )

  // .finally( ( err, arg ) =>
  // {

  //   test.true( arg === undefined );
  //   test.true( _.errIs( err ) );
  //   test.identical( singleErrorBeforeScalar.exitCode, undefined );
  //   test.identical( singleErrorBeforeScalar.output, undefined );
  //   test.true( !a.fileProvider.fileExists( filePath ) );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'single, error in ready, exec is single-element vector';
  //   time = _.time.now();
  //   throw _.err( 'Error!' );
  // })

  // let singleErrorBefore2 = {};
  // let singleErrorBefore =
  // {
  //   execPath : [ 'node ' + testAppPath + ' 1000' ],
  //   ready : a.ready,
  //   verbosity : 3,
  //   outputCollecting : 1,
  // }

  // var start = _.process.starter( singleErrorBefore );
  // start( singleErrorBefore2 )

  // .finally( ( err, arg ) =>
  // {

  //   test.true( arg === undefined );
  //   test.true( _.errIs( err ) );
  //   test.identical( singleErrorBefore.exitCode, undefined );
  //   test.identical( singleErrorBefore.output, undefined );
  //   test.true( !a.fileProvider.fileExists( filePath ) );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesOptionsSerial2 = {};
  // let subprocessesOptionsSerial =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  // }

  // var start = _.process.starter( subprocessesOptionsSerial );
  // start( subprocessesOptionsSerial2 )

  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesOptionsSerial2.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial, error, throwingExitCode : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesError2 = {};
  // let subprocessesError =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  // }

  // var start = _.process.starter( subprocessesError );
  // start( subprocessesError2 )

  // .finally( ( err, arg ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesError2.exitCode, 1 );
  //   test.true( _.errIs( err ) );
  //   test.true( arg === undefined );
  //   test.true( !a.fileProvider.fileExists( filePath ) );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, serial, error, throwingExitCode : 0';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorNonThrowing2 = {};
  // let subprocessesErrorNonThrowing =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 0,
  //   throwingExitCode : 0,
  // }

  // var start = _.process.starter( subprocessesErrorNonThrowing );
  // start( subprocessesErrorNonThrowing2 )

  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorNonThrowing2.exitCode, 1 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 1 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
  //   test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1, error, throwingExitCode : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorConcurrent2 = {};
  // let subprocessesErrorConcurrent =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // var start = _.process.starter( subprocessesErrorConcurrent );
  // start( subprocessesErrorConcurrent2 )

  // .finally( ( err, arg ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorConcurrent2.exitCode, 1 );
  //   test.true( _.errIs( err ) );
  //   test.true( arg === undefined );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   _.errAttend( err );
  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1, error, throwingExitCode : 0';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesErrorConcurrentNonThrowing2 = {};
  // let subprocessesErrorConcurrentNonThrowing =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' x', 'node ' + testAppPath + ' 1' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  //   throwingExitCode : 0,
  // }

  // var start = _.process.starter( subprocessesErrorConcurrentNonThrowing );
  // start( subprocessesErrorConcurrentNonThrowing2 )

  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent );
  //   test.gt( spent, 0 );
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesErrorConcurrentNonThrowing2.exitCode, 1 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 1 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin x' ) );
  //   test.true( !_.strHas( op.sessions[ 0 ].output, 'end x' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'Expects number' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 1' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 1' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'subprocesses, concurrent : 1';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesConcurrentOptions2 = {};
  // let subprocessesConcurrentOptions =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // var start = _.process.starter( subprocessesConcurrentOptions );
  // start( subprocessesConcurrentOptions2 )

  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent )
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesConcurrentOptions2.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 100' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // a.ready.then( ( arg ) =>
  // {
  //   test.case = 'args';
  //   time = _.time.now();
  //   return null;
  // })

  // let subprocessesConcurrentArgumentsOptions2 = {}
  // let subprocessesConcurrentArgumentsOptions =
  // {
  //   execPath :  [ 'node ' + testAppPath + ' 1000', 'node ' + testAppPath + ' 100' ],
  //   args : [ 'second', 'argument' ],
  //   ready : a.ready,
  //   outputCollecting : 1,
  //   verbosity : 3,
  //   concurrent : 1,
  // }

  // var start = _.process.starter( subprocessesConcurrentArgumentsOptions );
  // start( subprocessesConcurrentArgumentsOptions2 )

  // .then( ( op ) =>
  // {

  //   var spent = _.time.now() - time;
  //   logger.log( 'Spent', spent )
  //   test.gt( spent, context.t1 ); /* 1000 */
  //   test.le( spent, context.t1 * 5 ); /* 5000 */

  //   test.identical( subprocessesConcurrentArgumentsOptions2.exitCode, 0 );
  //   test.identical( op.sessions.length, 2 );
  //   test.identical( a.fileProvider.fileRead( filePath ), 'written by 1000' );
  //   a.fileProvider.fileDelete( filePath );

  //   test.identical( op.sessions[ 0 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'begin 1000, second, argument' ) );
  //   test.true( _.strHas( op.sessions[ 0 ].output, 'end 1000, second, argument' ) );

  //   test.identical( op.sessions[ 1 ].exitCode, 0 );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'begin 100, second, argument' ) );
  //   test.true( _.strHas( op.sessions[ 1 ].output, 'end 100, second, argument' ) );

  //   counter += 1;
  //   return null;
  // });

  // /* - */

  // return a.ready.finally( ( err, arg ) =>
  // {
  //   debugger;
  //   test.identical( counter, 12 );
  //   if( err )
  //   throw err;
  //   return arg;
  // });

  /* - */

  function program1()
  {
    var ended = 0;
    var fs = require( 'fs' );
    var path = require( 'path' );
    var filePath = path.join( __dirname, 'file.txt' );
    console.log( 'begin', process.argv.slice( 2 ).join( ', ' ) );
    var time = parseInt( process.argv[ 2 ] );
    if( isNaN( time ) )
    throw new Error( 'Expects number' );

    setTimeout( end, time );
    function end()
    {
      ended = 1;
      fs.writeFileSync( filePath, 'written by ' + process.argv[ 2 ] );
      console.log( 'end', process.argv.slice( 2 ).join( ', ' ) );
    }

    setTimeout( periodic, context.t1 / 20 ); /* 50 */
    function periodic()
    {
      console.log( 'tick', process.argv.slice( 2 ).join( ', ' ) );
      if( !ended )
      setTimeout( periodic, context.t1 / 20 ); /* 50 */
    }
  }
}

starterConcurrentMultiple.timeOut = 27e4; /* Locally : 26.982s */

// --
// helper
// --

function startNjs( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  var testAppPath = a.program( testApp );
  var testAppPath2 = a.program( testApp2 );

  /* */

  a.ready.then( () =>
  {
    test.case = 'execPath contains normalized path'
    return _.process.startNjs
    ({
      execPath : testAppPath2,
      args : [ 'arg' ],
      outputCollecting : 1,
      stdio : 'pipe',
    })
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.identical( op.args, [ 'arg' ] );
      test.identical( op.args2, [ 'arg' ] );
      console.log( op.output )
      test.true( _.strHas( op.output, `[ 'arg' ]` ) );
      return null
    })
  })

  /* */

  // let modes = [ 'fork', 'exec', 'spawn', 'shell' ];
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.then( () =>
    {
      var o = { execPath : testAppPath, mode, applyingExitCode : 1, throwingExitCode : 1, stdio : 'ignore', outputPiping : 0, outputCollecting : 0 };
      var con = _.process.startNjs( o );
      return test.shouldThrowErrorAsync( con )
      .finally( () =>
      {
        test.identical( o.exitCode, 1 );
        test.identical( process.exitCode, 1 );
        process.exitCode = 0;
        return true;
      })
    })

    /* */

    a.ready.then( () =>
    {
      var o = { execPath : testAppPath, mode,  applyingExitCode : 1, throwingExitCode : 0, stdio : 'ignore', outputPiping : 0, outputCollecting : 0 };
      return _.process.startNjs( o )
      .finally( ( err, op ) =>
      {
        test.identical( o.exitCode, 1 );
        test.identical( process.exitCode, 1 );
        process.exitCode = 0;
        test.true( !_.errIs( err ) );
        return true;
      })
    })

    /* */

    a.ready.then( () =>
    {
      var o = { execPath : testAppPath,  mode, applyingExitCode : 0, throwingExitCode : 1, stdio : 'ignore', outputPiping : 0, outputCollecting : 0 };
      var con = _.process.startNjs( o )
      return test.shouldThrowErrorAsync( con )
      .finally( () =>
      {
        test.identical( o.exitCode, 1 );
        test.identical( process.exitCode, 0 );
        return true;
      })
    })

    /* */

    a.ready.then( () =>
    {
      var o = { execPath : testAppPath,  mode, applyingExitCode : 0, throwingExitCode : 0, stdio : 'ignore', outputPiping : 0, outputCollecting : 0 };
      return _.process.startNjs( o )
      .finally( ( err, op ) =>
      {
        test.identical( o.exitCode, 1 );
        test.identical( process.exitCode, 0 );
        test.true( !_.errIs( err ) );
        return true;
      })
    })

    /* */

    a.ready.then( () =>
    {
      var o = { execPath : testAppPath,  mode, maximumMemory : 1, applyingExitCode : 0, throwingExitCode : 0, stdio : 'ignore', outputPiping : 0, outputCollecting : 0 };
      return _.process.startNjs( o )
      .finally( ( err, op ) =>
      {
        test.identical( o.exitCode, 1 );
        test.identical( process.exitCode, 0 );
        let spawnArgs = _.toStr( o.pnd.spawnargs, { levels : 99 } );
        test.true( _.strHasAll( spawnArgs, [ '--expose-gc',  '--stack-trace-limit=999', '--max_old_space_size=' ] ) )
        test.true( !_.errIs( err ) );
        return true;
      })
    })
  })

  return a.ready;

  /* - */

  function testApp()
  {
    throw new Error( 'Error message from child' );
  }

  function testApp2()
  {
    console.log( process.argv.slice( 2 ) )
  }

}

startNjs.timeOut = 20000;

//

function startNjsWithReadyDelayStructural( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 0, detaching : 0, mode }) ) );

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 0, detaching : 1, mode }) ) );

  return a.ready;

  /* */

  function run( tops )
  {
    let ready = _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return null;

    ready.then( () =>
    {
      /*
      output piping doesn't work as expected in mode "shell" on windows
      */
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, dry : ${tops.dry}, detaching : ${tops.detaching}`;
      let con = new _.Consequence().take( null ).delay( context.t1 ); /* 1000 */

      let options =
      {
        mode : tops.mode,
        detaching : tops.detaching,
        dry : tops.dry,
        execPath : programPath,
        currentPath : a.abs( '.' ),
        throwingExitCode : 1,
        inputMirroring : 1,
        outputCollecting : 1,
        stdio : 'pipe',
        sync : tops.sync,
        deasync : tops.deasync,
        ready : con,
      }

      let returned = _.process.startNjs( options );

      if( tops.sync )
      test.true( !_.consequenceIs( returned ) )
      else
      test.true( _.consequenceIs( returned ) )

      var exp =
      {
        'mode' : tops.mode,
        'detaching' : tops.detaching,
        'dry' : tops.dry,
        'execPath' : ( tops.mode === 'fork' ? '' : 'node ' ) + programPath,
        'currentPath' : a.abs( '.' ),
        'throwingExitCode' : 'full',
        'inputMirroring' : 1,
        'outputCollecting' : 1,
        'sync' : tops.sync,
        'deasync' : tops.deasync,
        'passingThrough' : 0,
        'maximumMemory' : 0,
        'applyingExitCode' : 1,
        'stdio' : tops.mode === 'fork' ? [ 'pipe', 'pipe', 'pipe', 'ipc' ] : [ 'pipe', 'pipe', 'pipe' ],
        'args' : null,
        'args2' : null,
        'interpreterArgs' : null,
        'when' : 'instant',
        'ipc' : tops.mode === 'fork' ? true : false,
        'env' : null,
        'hiding' : 1,
        'concurrent' : 0,
        'timeOut' : null,
        // 'briefExitCode' : 0,
        'verbosity' : 2,
        'outputPrefixing' : 0,
        'outputPiping' : true,
        'outputAdditive' : true,
        'outputColoring' : { err : 1, out : 1 },
        'uid' : null,
        'gid' : null,
        'streamSizeLimit' : null,
        'streamOut' : null,
        'streamErr' : null,
        'outputGraying' : 0,
        'conStart' : options.conStart,
        'conTerminate' : options.conTerminate,
        'conDisconnect' : options.conDisconnect,
        'ready' : options.ready,
        'process' : options.pnd,
        'logger' : options.logger,
        'stack' : options.stack,
        'state' : 'initial',
        'exitReason' : null,
        'output' : '',
        'exitCode' : null,
        'exitSignal' : null,
        'procedure' : null,
        'ended' : false,
        'error' : null,
        'disconnect' : options.disconnect,
        'end' : options.end,
        'fullExecPath' : null,
        '_handleProcedureTerminationBegin' : false,
      }

      options.ready.then( ( op ) =>
      {
        let exp2 = _.mapExtend( null, exp );
        exp2.process = options.pnd;
        exp2.procedure = options.procedure;
        exp2.streamOut = options.streamOut;
        exp2.streamErr = options.streamErr;
        exp2.execPath = tops.mode === 'fork' ? programPath : 'node';
        exp2.args = tops.mode === 'fork' ? [] : [ programPath ];
        exp2.args2 = tops.mode === 'fork' ? [] : [ programPath ];
        exp2.fullExecPath = ( tops.mode === 'fork' ? '' : 'node ' ) + programPath;
        exp2.state = 'terminated';
        exp2.ended = true;

        if( tops.dry )
        {
          test.identical( op.output, '' );
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, null );
          test.identical( op.exitReason, null );
        }
        else
        {
          /* exception in njs on Windows :
            no output from detached process in mode::shell
          */
          if( tops.mode !== 'shell' || process.platform !== 'win32' || !tops.detaching )
          test.identical( op.output, 'program1:begin\n' );
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.identical( op.exitReason, 'normal' );
          /* exception in njs on Windows :
            no output from detached process in mode::shell
          */
          if( tops.mode !== 'shell' || process.platform !== 'win32' || !tops.detaching )
          exp2.output = 'program1:begin\n';
          exp2.exitCode = 0;
          exp2.exitSignal = null;
          exp2.exitReason = 'normal';
        }

        test.identical( options, exp2 );
        test.identical( !!options.pnd, !tops.dry );
        test.true( _.routineIs( options.disconnect ) );
        test.identical( _.streamIs( options.streamOut ), !tops.dry && ( !tops.sync || !!tops.deasync ) );
        test.identical( _.streamIs( options.streamErr ), !tops.dry && ( !tops.sync || !!tops.deasync ) );
        test.identical( options.streamOut !== options.streamErr, !tops.dry && ( !tops.sync || !!tops.deasync ) );
        test.true( options.conTerminate !== options.ready );
        if( tops.sync || tops.deasync )
        test.identical( options.ready.exportString(), 'Consequence:: 0 / 0' );
        else
        test.identical( options.ready.exportString(), 'Consequence:: 0 / 1' );

        test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conDisconnect.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );

        return null;
      });

      if( !tops.sync && !tops.deasync )
      {
        test.identical( options, exp );
      }
      else
      {
        let exp2 = _.mapExtend( null, exp );
        exp2.execPath = tops.mode === 'fork' ? exp2.execPath : 'node';
        exp2.args = tops.mode === 'fork' ? [] : [ programPath ];
        exp2.args2 = tops.mode === 'fork' ? [] : [ programPath ];
        exp2.fullExecPath = tops.mode === 'fork' ? programPath : 'node ' + programPath;
        exp2.streamOut = options.streamOut;
        exp2.streamErr = options.streamErr;
        exp2.procedure = options.procedure;
        exp2._end = options._end;
        exp2.state = 'terminated';
        exp2.exitCode = tops.dry ? null : 0;
        exp2.exitReason =  tops.dry ? null : 'normal';
        exp2.ended = true;
        exp2.output = tops.dry ? '' :'program1:begin\n';
        delete exp2.end;

        test.identical( options, exp2 )
      }

      test.true( _.routineIs( options.disconnect ) );
      test.true( options.conTerminate !== options.ready );
      if( ( tops.sync || tops.deasync ) && !tops.dry )
      {
        test.notIdentical( options.pnd, null );
      }
      else
      {
        test.identical( options.pnd, null );
      }
      test.true( !!options.logger );
      test.true( !!options.stack );
      if( tops.sync || tops.deasync )
      {
        test.identical( options.ready.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conDisconnect.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );
      }
      else
      {
        test.identical( options.ready.exportString(), 'Consequence:: 0 / 2' );
        test.identical( options.conDisconnect.exportString(), 'Consequence:: 0 / 0' );
        test.identical( options.conTerminate.exportString(), 'Consequence:: 0 / 0' );
        test.identical( options.conStart.exportString(), 'Consequence:: 0 / 0' );
      }

      return returned;
    })

    return ready;
  }

  /* */

  function program1()
  {
    console.log( 'program1:begin' );
  }

}

startNjsWithReadyDelayStructural.timeOut = 33e4; /* Locally : 32.486s */
startNjsWithReadyDelayStructural.rapidity = -1;
startNjsWithReadyDelayStructural.description =
`
 - ready has delay
 - value of o-context is correct before start
 - value of o-context is correct after start
`

//

function startNjsOptionInterpreterArgs( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let totalMem = require( 'os' ).totalmem();

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = ''`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : '',
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' );
        test.identical( op.interpreterArgs, [] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ programPath ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = []`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : [],
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' );
        test.identical( op.interpreterArgs, [] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ programPath ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = '--version'`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : '--version',
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version' ] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ '--version', programPath ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, execPath : null, args : programPath, interpreterArgs = '--version'`;

      let options =
      {
        args : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : '--version',
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version' ] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ '--version', programPath ] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ '--version', _.strQuote( programPath ) ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, execPath : '', args : 'arg1', interpreterArgs = '--version'`;

      let options =
      {
        execPath : '',
        args : 'arg1',
        mode,
        outputCollecting : 1,
        interpreterArgs : '--version',
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version' ] );
        if( mode === 'shell' )
        {
          test.identical( op.args, [ 'arg1' ] );
          test.identical( op.args2, [ '--version', '"arg1"' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ 'arg1' ] );
          test.identical( op.args2, [ '--version', 'arg1' ] );
        }
        else
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = '--version', maximumMemory : 1`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : '--version',
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        if( mode === 'shell' ) console.log( 'SHELL OP: ', op )
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          let exp =
          [
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
          ]
          test.identical( op.args2, exp );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = [ '--v8-options' ]`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : [ '--v8-options' ],
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'Options:' ) );

        test.identical( op.interpreterArgs, [ '--v8-options' ] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          test.identical( op.args2, [ '--v8-options', programPath ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = [ '--v8-options' ], maximumMemory : 1`;

      let options =
      {
        execPath : programPath,
        mode,
        outputCollecting : 1,
        interpreterArgs : [ '--v8-options' ],
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'Options:' ) );

        test.identical( op.interpreterArgs, [ '--v8-options', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );
        if( mode === 'fork' )
        {
          test.identical( op.args, [] );
          test.identical( op.args2, [] );
        }
        else
        {
          test.identical( op.args, [ programPath ] );
          let exp =
          [
            '--v8-options',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
          ]
          test.identical( op.args2, exp );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = '--version', maximumMemory : 1, args : [ 'arg1', 'arg2' ]`;

      let options =
      {
        execPath : programPath,
        mode,
        args : [ 'arg1', 'arg2' ],
        outputCollecting : 1,
        interpreterArgs : '--version',
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );

        if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            '"arg1"',
            '"arg2"'
          ]
          test.identical( op.args2, exp );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            'arg1',
            'arg2'
          ]
          test.identical( op.args2, exp );
        }
        else
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = '--trace-warnings --version', maximumMemory : 1, args : [ 'arg1', 'arg2' ]`;

      let options =
      {
        execPath : programPath,
        mode,
        args : [ 'arg1', 'arg2' ],
        outputCollecting : 1,
        interpreterArgs : '--trace-warnings --version',
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );
        test.identical( op.interpreterArgs, [ '--trace-warnings', '--version', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );

        if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--trace-warnings',
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            '"arg1"',
            '"arg2"'
          ]
          test.identical( op.args2, exp );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--trace-warnings',
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            'arg1',
            'arg2'
          ]
          test.identical( op.args2, exp );
        }
        else
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = [ '--trace-warnings', '--version' ], maximumMemory : 1, args : [ 'arg1', 'arg2' ]`;

      let options =
      {
        execPath : programPath,
        mode,
        args : [ 'arg1', 'arg2' ],
        outputCollecting : 1,
        interpreterArgs : [ '--trace-warnings', '--version' ],
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--trace-warnings', '--version', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );

        if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--trace-warnings',
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            '"arg1"',
            '"arg2"'
          ]
          test.identical( op.args2, exp );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--trace-warnings',
            '--version',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            'arg1',
            'arg2'
          ]
          test.identical( op.args2, exp );
        }
        else
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, interpreterArgs = [ '--version', '--v8-options' ], maximumMemory : 1, args : [ 'arg1', 'arg2' ]`;

      let options =
      {
        execPath : programPath,
        mode,
        args : [ 'arg1', 'arg2' ],
        outputCollecting : 1,
        interpreterArgs : [ '--version', '--v8-options' ],
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );
        test.identical( op.interpreterArgs, [ '--version', '--v8-options', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );

        if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--v8-options',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            '"arg1"',
            '"arg2"'
          ]
          test.identical( op.args2, exp );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--v8-options',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            'arg1',
            'arg2'
          ]
          test.identical( op.args2, exp );
        }
        else
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode}, execPath : null, interpreterArgs = [ '--version', '--v8-options' ], maximumMemory : 1, args : [ programPath,  'arg1', 'arg2' ]`;

      let options =
      {
        execPath : null,
        mode,
        args : [ programPath, 'arg1', 'arg2' ],
        outputCollecting : 1,
        interpreterArgs : [ '--version', '--v8-options' ],
        maximumMemory : 1,
        stdio : 'pipe'
      }

      return _.process.startNjs( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, process.version );

        test.identical( op.interpreterArgs, [ '--version', '--v8-options', '--expose-gc', '--stack-trace-limit=999', `--max_old_space_size=${totalMem}` ] );

        if( mode === 'shell' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--v8-options',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            _.strQuote( programPath ),
            '"arg1"',
            '"arg2"'
          ]
          test.identical( op.args2, exp );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ programPath, 'arg1', 'arg2' ] );
          let exp =
          [
            '--version',
            '--v8-options',
            '--expose-gc',
            '--stack-trace-limit=999',
            `--max_old_space_size=${totalMem}`,
            programPath,
            'arg1',
            'arg2'
          ]
          test.identical( op.args2, exp );
        }
        else
        {
          test.identical( op.args, [ 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg1', 'arg2' ] );
        }

        return null;
      })
    })

    return ready;

  }

  /* - */

  function program1()
  {
    console.log( 'Log' );
  }
}

//

function startNjsWithReadyDelayStructuralMultiple( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, dry : 0, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 0, detaching : 0, mode }) ) );

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 1, detaching : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, dry : 0, detaching : 1, mode }) ) );

  /* ORIGINAL ( detaching, mode ) */
  // modes.forEach( ( mode ) => a.ready.then( () => run( 0, mode ) ) );
  // modes.forEach( ( mode ) => a.ready.then( () => run( 1, mode ) ) );
  return a.ready;

  /* */

  function run( tops )
  {
    let ready = _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return null;

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, dry : ${tops.dry}, detaching:${tops.detaching}`;
      let con = new _.Consequence().take( null ).delay( context.t1 ); /* 1000 */

      let options =
      {
        mode : tops.mode,
        detaching : tops.detaching,
        execPath : programPath,
        currentPath : [ a.abs( '.' ), a.abs( '.' ) ],
        throwingExitCode : 1,
        inputMirroring : 1,
        outputCollecting : 1,
        stdio : 'pipe',
        sync : tops.sync,
        deasync : tops.deasync,
        dry : tops.dry,
        ready : con,
      }

      let returned = _.process.startNjs( options );

      if( tops.sync )
      test.true( !_.consequenceIs( returned ) )
      else
      test.true( _.consequenceIs( returned ) )

      var exp =
      {
        'mode' : tops.mode,
        'detaching' : tops.detaching,
        'execPath' : ( tops.mode === 'fork' ? '' : 'node ' ) + programPath,
        'currentPath' : [ a.abs( '.' ), a.abs( '.' ) ],
        'throwingExitCode' : 'full',
        'inputMirroring' : 1,
        'outputCollecting' : 1,
        'sync' : tops.sync,
        'deasync' : tops.deasync,
        'passingThrough' : 0,
        'maximumMemory' : 0,
        'applyingExitCode' : 1,
        'stdio' : tops.mode === 'fork' ? [ 'pipe', 'pipe', 'pipe', 'ipc' ] : [ 'pipe', 'pipe', 'pipe' ],
        'args' : null,
        'interpreterArgs' : null,
        'when' : 'instant',
        'dry' : tops.dry,
        'ipc' : tops.mode === 'fork' ? true : false,
        'env' : null,
        'hiding' : 1,
        'concurrent' : 0,
        'timeOut' : null,
        // 'briefExitCode' : 0,
        'verbosity' : 2,
        'outputPrefixing' : 0,
        'outputPiping' : true,
        'outputAdditive' : true,
        'outputColoring' : { err : 1, out : 1 },
        'outputGraying' : 0,
        'conStart' : options.conStart,
        'conTerminate' : options.conTerminate,
        'conDisconnect' : options.conDisconnect,
        'ready' : options.ready,
        'procedure' : options.procedure,
        'logger' : options.logger,
        'stack' : options.stack,
        'streamOut' : options.streamOut,
        'streamErr' : options.streamErr,
        'uid' : null,
        'gid' : null,
        'streamSizeLimit' : null,
        'sessions' : [],
        'state' : 'initial',
        'exitReason' : null,
        'output' : '',
        'exitCode' : null,
        'exitSignal' : null,
        'ended' : false,
        'error' : null
        // 'disconnect' : options.disconnect,
        // 'fullExecPath' : null,
        // '_handleProcedureTerminationBegin' : false,
      }

      options.ready.then( ( op ) =>
      {
        let exp2 = _.mapExtend( null, exp );

        exp2.sessions = options.sessions;
        exp2.state = 'terminated';
        exp2.exitReason = 'normal';
        exp2.ended = true;

        if( tops.dry )
        {
          test.identical( op.output, '' );
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, null );
          test.identical( op.exitReason, 'normal' );
        }
        else
        {
          /* exception in njs on Windows :
            no output from detached process in mode::shell
          */
          if( tops.mode !== 'shell' || process.platform !== 'win32' || !tops.detaching )
          test.identical( op.output, 'program1:begin\nprogram1:begin\n' );
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.identical( op.exitReason, 'normal' );
          /* exception in njs on Windows :
            no output from detached process in mode::shell
          */
          if( tops.mode !== 'shell' || process.platform !== 'win32' || !tops.detaching )
          exp2.output = 'program1:begin\nprogram1:begin\n';
          exp2.exitCode = 0;
          exp2.exitSignal = null;
          exp2.exitReason = 'normal';
        }

        test.identical( options, exp2 );
        test.true( !options.pnd );
        test.true( !options.disconnect );
        test.identical( _.streamIs( options.streamOut ), !tops.sync || ( !!tops.sync && !!tops.deasync ) );
        test.identical( _.streamIs( options.streamErr ), !tops.sync || ( !!tops.sync && !!tops.deasync ) );
        test.identical( options.streamOut !== options.streamErr, !tops.sync || ( !!tops.sync && !!tops.deasync ) );
        test.true( options.conTerminate !== options.ready );
        test.true( _.arrayIs( options.sessions ) );

        if( tops.sync || tops.deasync )
        {
          test.identical( options.ready.exportString(), 'Consequence:: 0 / 0' );
          test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
          test.identical( options.conDisconnect, null );
          test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );
        }
        else
        {
          test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
          test.identical( options.conDisconnect, null );
          test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );
          test.identical( options.ready.exportString(), 'Consequence:: 0 / 1' );
        }

        /* Added sessions' checks */
        op.sessions.forEach( ( run ) =>
        {
          if( tops.dry )
          {
            test.identical( run.output, '' );
            test.identical( run.exitCode, null );
            test.identical( run.exitReason, null );
          }
          else
          {
            /* exception in njs on Windows :
              no output from detached process in mode::shell
            */
            if( tops.mode !== 'shell' || process.platform !== 'win32' || !tops.detaching )
            test.identical( run.output, 'program1:begin\n' );
            else
            test.identical( run.output, '' );
            test.identical( run.exitCode, 0 );
            test.identical( run.exitReason, 'normal' );
          }
          test.identical( run.exitSignal, null );
          test.identical( !!run.process, !tops.dry );
          test.true( _.routineIs( run.disconnect ) );
          test.identical( _.streamIs( run.streamOut ), !tops.dry && ( !tops.sync || !!tops.deasync ) );
          test.identical( _.streamIs( run.streamErr ), !tops.dry && ( !tops.sync || !!tops.deasync ) );
          test.identical( run.streamOut !== run.streamErr, !tops.dry && ( !tops.sync || !!tops.deasync ) );
          test.true( run.conTerminate !== run.ready );

          test.identical( run.ready.exportString(), 'Consequence:: 1 / 0' );
          test.identical( run.conTerminate.exportString(), 'Consequence:: 1 / 0' );
          test.identical( run.conDisconnect.exportString(), 'Consequence:: 1 / 0' );
          test.identical( run.conStart.exportString(), 'Consequence:: 1 / 0' );

        })

        return null;
      });

      let exp3 = _.mapExtend( null, exp );
      if( tops.sync || tops.deasync )
      {
        exp3.ended = true;
        exp3.exitCode = tops.dry ? null : 0;
        exp3.state = 'terminated';
        exp3.exitReason = 'normal';
        exp3.output = tops.dry ? '' : 'program1:begin\nprogram1:begin\n';
        exp3.sessions = options.sessions;
      }

      test.identical( options, exp3 );

      test.true( options.conTerminate !== options.ready );
      test.true( !options.disconnect );
      test.true( !options.pnd );
      test.true( !!options.procedure );
      test.true( !!options.logger );
      test.true( !!options.stack );
      test.identical( _.streamIs( options.streamOut ), !tops.sync || ( !!tops.sync && !!tops.deasync ) );
      test.identical( _.streamIs( options.streamErr ), !tops.sync || ( !!tops.sync && !!tops.deasync ) );
      test.identical( options.streamOut !== options.streamErr, !tops.sync || ( !!tops.sync && !!tops.deasync ) );
      test.identical( options.conDisconnect, null );
      if( tops.sync || tops.deasync )
      {
        test.identical( options.ready.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
        test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );
      }
      else
      {
        test.identical( options.ready.exportString(), 'Consequence:: 0 / 3' );
        test.identical( options.conTerminate.exportString(), 'Consequence:: 0 / 0' );
        test.identical( options.conStart.exportString(), 'Consequence:: 0 / 0' );
      }

      return returned;
    })

    return ready;
  }

  /* */

  function program1()
  {
    console.log( 'program1:begin' );
  }

  /* ORIGINAL */
  // ready.then( () =>
  // {
  //   test.case = `mode:${mode} detaching:${detaching}`;
  //   let con = new _.Consequence().take( null ).delay( context.t1 ); /* 1000 */

  //   let options =
  //   {
  //     mode,
  //     detaching,
  //     execPath : programPath,
  //     currentPath : [ a.abs( '.' ), a.abs( '.' ) ],
  //     throwingExitCode : 1,
  //     inputMirroring : 1,
  //     outputCollecting : 1,
  //     stdio : 'pipe',
  //     sync : 0,
  //     deasync : 0,
  //     ready : con,
  //   }

  //   let returned = _.process.startNjs( options );

  //   returned.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( op.output, 'program1:begin\nprogram1:begin\n' );

  //     let exp2 = _.mapExtend( null, exp );
  //     exp2.output = 'program1:begin\nprogram1:begin\n';
  //     exp2.exitCode = 0;
  //     exp2.exitSignal = null;
  //     exp2.sessions = options.sessions;
  //     exp2.state = 'terminated';
  //     exp2.exitReason = 'normal';
  //     exp2.ended = true;

  //     test.identical( options, exp2 );
  //     test.true( !options.pnd );
  //     test.true( _.streamIs( options.streamOut ) );
  //     test.true( _.streamIs( options.streamErr ) );
  //     test.true( options.streamOut !== options.streamErr );
  //     test.true( ! options.disconnect );
  //     test.true( options.conTerminate !== options.ready );
  //     test.true( _.arrayIs( options.sessions ) );
  //     test.identical( options.ready.exportString(), 'Consequence:: 0 / 1' );
  //     test.identical( options.conTerminate.exportString(), 'Consequence:: 1 / 0' );
  //     test.identical( options.conDisconnect, null );
  //     test.identical( options.conStart.exportString(), 'Consequence:: 1 / 0' );

  //     return null;
  //   });

  //   var exp =
  //   {
  //     mode,
  //     detaching,
  //     'execPath' : ( mode === 'fork' ? '' : 'node ' ) + programPath,
  //     'currentPath' : [ a.abs( '.' ), a.abs( '.' ) ],
  //     'throwingExitCode' : 'full',
  //     'inputMirroring' : 1,
  //     'outputCollecting' : 1,
  //     'sync' : 0,
  //     'deasync' : 0,
  //     'passingThrough' : 0,
  //     'maximumMemory' : 0,
  //     'applyingExitCode' : 1,
  //     'stdio' : mode === 'fork' ? [ 'pipe', 'pipe', 'pipe', 'ipc' ] : [ 'pipe', 'pipe', 'pipe' ],
  //     'streamOut' : null,
  //     'streamErr' : null,
  //     'args' : null,
  //     'interpreterArgs' : null,
  //     'when' : 'instant',
  //     'dry' : 0,
  //     'ipc' : mode === 'fork' ? true : false,
  //     'env' : null,
  //     'hiding' : 1,
  //     'concurrent' : 0,
  //     'timeOut' : null,
  //     // 'briefExitCode' : 0,
  //     'verbosity' : 2,
  //     'outputPrefixing' : 0,
  //     'outputPiping' : true,
  //     'outputAdditive' : true,
  //     'outputColoring' : 1,
  //     'outputColoringStdout' : 1,
  //     'outputColoringStderr' : 1,
  //     'outputGraying' : 0,
  //     'conStart' : options.conStart,
  //     'conTerminate' : options.conTerminate,
  //     'conDisconnect' : options.conDisconnect,
  //     'ready' : options.ready,
  //     'procedure' : options.procedure,
  //     'logger' : options.logger,
  //     'stack' : options.stack,
  //     'streamOut' : options.streamOut,
  //     'streamErr' : options.streamErr,
  //     'uid' : null,
  //     'gid' : null,
  //     'streamSizeLimit' : null,
  //     'sessions' : [],
  //     'state' : 'initial',
  //     'exitReason' : null,
  //     'output' : '',
  //     'exitCode' : null,
  //     'exitSignal' : null,
  //     'ended' : false,
  //     'error' : null
  //     // 'disconnect' : options.disconnect,
  //     // 'fullExecPath' : null,
  //     // '_handleProcedureTerminationBegin' : false,
  //   }
  //   test.identical( options, exp );

  //   test.true( options.conTerminate !== options.ready );
  //   test.true( !options.disconnect );
  //   test.true( !options.pnd );
  //   test.true( !!options.procedure );
  //   test.true( !!options.logger );
  //   test.true( !!options.stack );
  //   test.true( _.streamIs( options.streamOut ) );
  //   test.true( _.streamIs( options.streamErr ) );
  //   test.true( options.streamOut !== options.streamErr );
  //   test.identical( options.ready.exportString(), 'Consequence:: 0 / 3' );
  //   test.identical( options.conTerminate.exportString(), 'Consequence:: 0 / 0' );
  //   test.identical( options.conDisconnect, null );
  //   test.identical( options.conStart.exportString(), 'Consequence:: 0 / 0' );

  //   return returned;
  // })

}

startNjsWithReadyDelayStructuralMultiple.timeOut = 38e4; /* Locally : 37.799s */
startNjsWithReadyDelayStructuralMultiple.rapidity = -1;
startNjsWithReadyDelayStructuralMultiple.description =
`
 - ready has delay
 - value of o-context is correct before start
 - value of o-context is correct after start
`

// --
// starter
// --

function starter( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : path, run with execPath : array of args`;

      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      debugger;
      return shell({ execPath : [ 'arg1', 'arg2' ] })
      .then( ( op ) =>
      {
        debugger;
        test.identical( op.sessions.length, 2 );

        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];

        if( mode === 'fork' )
        {
          test.identical( o1.execPath, testAppPath );
          test.identical( o2.execPath, testAppPath );
        }
        else
        {
          test.identical( o1.execPath, 'node' );
          test.identical( o2.execPath, 'node' );
        }
        test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
        test.true( _.strHas( o2.output, `[ 'arg2' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : path and 'arg0', run with execPath : array of args`;

      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? testAppPath + ' arg0' : 'node ' + testAppPath + ' arg0',
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : [ 'arg1', 'arg2' ] })
      .then( ( op ) =>
      {
        test.identical( op.sessions.length, 2 );

        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];

        if( mode === 'fork' )
        {
          test.identical( o1.execPath, testAppPath );
          test.identical( o2.execPath, testAppPath );
        }
        else
        {
          test.identical( o1.execPath, 'node' );
          test.identical( o2.execPath, 'node' );
        }
        test.true( _.strHas( o1.output, `[ 'arg0', 'arg1' ]` ) );
        test.true( _.strHas( o2.output, `[ 'arg0', 'arg2' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : path, run with execPath : array of args, args : array with 1 arg`;
      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : [ 'arg1', 'arg2' ], args : [ 'arg3' ] })
      .then( ( op ) =>
      {
        test.identical( op.sessions.length, 2 );

        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];

        if( mode === 'fork' )
        {
          test.identical( o1.execPath, testAppPath );
          test.identical( o2.execPath, testAppPath );
          test.identical( o1.args, [ 'arg1', 'arg3' ] );
          test.identical( o2.args, [ 'arg2', 'arg3' ] );
        }
        else
        {
          test.identical( o1.execPath, 'node' );
          test.identical( o2.execPath, 'node' );
          test.identical( o1.args, [ testAppPath, 'arg1', 'arg3' ] );
          test.identical( o2.args, [ testAppPath, 'arg2', 'arg3' ] );
        }

        test.true( _.strHas( o1.output, `[ 'arg1', 'arg3' ]` ) );
        test.true( _.strHas( o2.output, `[ 'arg2', 'arg3' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : path, run with execPath : 'arg1'`;
      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : 'arg1' })
      .then( ( op ) =>
      {

        if( mode === 'fork' )
        test.identical( op.execPath, testAppPath );
        else
        test.identical( op.execPath, 'node' );
        test.true( _.strHas( op.output, `[ 'arg1' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : array of paths, run with execPath : 'arg1'`;

      var shell = _.process.starter
      ({
        execPath :
        [
          `${mode === 'fork' ? '' : 'node '}` + testAppPath,
          `${mode === 'fork' ? '' : 'node '}` + testAppPath,
        ],
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : 'arg1' })
      .then( ( op ) =>
      {
        test.identical( op.sessions.length, 2 );

        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];

        if( mode === 'fork' )
        {
          test.identical( o1.execPath, testAppPath );
          test.identical( o2.execPath, testAppPath );
        }
        else
        {
          test.identical( o1.execPath, 'node' );
          test.identical( o2.execPath, 'node' );
        }
        test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
        test.true( _.strHas( o2.output, `[ 'arg1' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : array of paths, run with execPath : array of args`;

      var shell = _.process.starter
      ({
        execPath :
        [
          `${mode === 'fork' ? '' : 'node '}` + testAppPath,
          `${mode === 'fork' ? '' : 'node '}` + testAppPath,
        ],
        mode,
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : [ 'arg1', 'arg2' ] })
      .then( ( op ) =>
      {
        test.identical( op.sessions.length, 4 );

        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];
        let o3 = op.sessions[ 2 ];
        let o4 = op.sessions[ 3 ];

        if( mode === 'fork' )
        {
          test.identical( o1.execPath, testAppPath );
          test.identical( o2.execPath, testAppPath );
          test.identical( o3.execPath, testAppPath );
          test.identical( o4.execPath, testAppPath );
        }
        else
        {
          test.identical( o1.execPath, 'node' );
          test.identical( o2.execPath, 'node' );
          test.identical( o3.execPath, 'node' );
          test.identical( o4.execPath, 'node' );
        }

        test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
        test.true( _.strHas( o2.output, `[ 'arg1' ]` ) );
        test.true( _.strHas( o3.output, `[ 'arg2' ]` ) );
        test.true( _.strHas( o4.output, `[ 'arg2' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : 'node', run with execPath : path`;

      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? '' : 'node',
        mode,
        args : 'arg1',
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : testAppPath })
      .then( ( op ) =>
      {
        if( mode === 'fork' )
        test.identical( op.execPath, testAppPath );
        else
        test.identical( op.execPath, 'node' );
        test.true( _.strHas( op.output, `[ 'arg1' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : 'node', args : 'arg1'; run with execPath : path, args : 'arg2'`;

      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? '' : 'node',
        mode,
        args : 'arg1',
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : testAppPath, args : 'arg2' })
      .then( ( op ) =>
      {
        if( mode === 'fork' )
        test.identical( op.execPath, testAppPath );
        else
        test.identical( op.execPath, 'node' );
        test.true( _.strHas( op.output, `[ 'arg2' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : 'node', args : array of args; run with execPath : path, args : 'arg2'`;

      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? '' : 'node',
        mode,
        args : [ 'arg1', 'arg2' ],
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : testAppPath, args : 'arg3' })
      .then( ( op ) =>
      {
        if( mode === 'fork' )
        test.identical( op.execPath, testAppPath );
        else
        test.identical( op.execPath, 'node' );
        test.true( _.strHas( op.output, `[ 'arg3' ]` ) );

        return op;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, execPath : 'node', args : 'arg1'; run with execPath : path, args : array of args`;
      var shell = _.process.starter
      ({
        execPath : mode === 'fork' ? '' : 'node',
        mode,
        args : 'arg1',
        outputCollecting : 1,
        outputPiping : 1
      })

      return shell({ execPath : testAppPath, args : [ 'arg2', 'arg3' ] })
      .then( ( op ) =>
      {
        if( mode === 'fork' )
        test.identical( op.execPath, testAppPath );
        else
        test.identical( op.execPath, 'node' );
        test.true( _.strHas( op.output, `[ 'arg2', 'arg3' ]` ) );

        return op;
      })
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :  'node ' + testAppPath,
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   debugger;
  //   return shell({ execPath :  [ 'arg1', 'arg2' ] })
  //   .then( ( op ) =>
  //   {
  //     debugger;
  //     test.identical( op.sessions.length, 2 );

  //     let o1 = op.sessions[ 0 ];
  //     let o2 = op.sessions[ 1 ];

  //     test.identical( o1.execPath, 'node' );
  //     test.identical( o2.execPath, 'node' );
  //     test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
  //     test.true( _.strHas( o2.output, `[ 'arg2' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :  'node ' + testAppPath + ' arg0',
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath :  [ 'arg1', 'arg2' ] })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.sessions.length, 2 );

  //     let o1 = op.sessions[ 0 ];
  //     let o2 = op.sessions[ 1 ];

  //     test.identical( o1.execPath, 'node' );
  //     test.identical( o2.execPath, 'node' );
  //     test.true( _.strHas( o1.output, `[ 'arg0', 'arg1' ]` ) );
  //     test.true( _.strHas( o2.output, `[ 'arg0', 'arg2' ]` ) );

  //     return op;
  //   })
  // })


  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :  'node ' + testAppPath,
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath :  [ 'arg1', 'arg2' ], args : [ 'arg3' ] })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.sessions.length, 2 );

  //     let o1 = op.sessions[ 0 ];
  //     let o2 = op.sessions[ 1 ];

  //     test.identical( o1.execPath, 'node' );
  //     test.identical( o2.execPath, 'node' );
  //     test.identical( o1.args, [ testAppPath, 'arg1', 'arg3' ] );
  //     test.identical( o2.args, [ testAppPath, 'arg2', 'arg3' ] );
  //     test.true( _.strHas( o1.output, `[ 'arg1', 'arg3' ]` ) );
  //     test.true( _.strHas( o2.output, `[ 'arg2', 'arg3' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :  'node ' + testAppPath,
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath :  'arg1' })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.execPath, 'node' );
  //     test.true( _.strHas( op.output, `[ 'arg1' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :
  //     [
  //       'node ' + testAppPath,
  //       'node ' + testAppPath
  //     ],
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath :  'arg1' })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.sessions.length, 2 );

  //     let o1 = op.sessions[ 0 ];
  //     let o2 = op.sessions[ 1 ];

  //     test.identical( o1.execPath, 'node' );
  //     test.identical( o2.execPath, 'node' );
  //     test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
  //     test.true( _.strHas( o2.output, `[ 'arg1' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath :
  //     [
  //       'node ' + testAppPath,
  //       'node ' + testAppPath
  //     ],
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath :  [ 'arg1', 'arg2' ] })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.sessions.length, 4 );

  //     let o1 = op.sessions[ 0 ];
  //     let o2 = op.sessions[ 1 ];
  //     let o3 = op.sessions[ 2 ];
  //     let o4 = op.sessions[ 3 ];

  //     test.identical( o1.execPath, 'node' );
  //     test.identical( o2.execPath, 'node' );
  //     test.identical( o3.execPath, 'node' );
  //     test.identical( o4.execPath, 'node' );
  //     test.true( _.strHas( o1.output, `[ 'arg1' ]` ) );
  //     test.true( _.strHas( o2.output, `[ 'arg1' ]` ) );
  //     test.true( _.strHas( o3.output, `[ 'arg2' ]` ) );
  //     test.true( _.strHas( o4.output, `[ 'arg2' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath : 'node',
  //     args : 'arg1',
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath : testAppPath })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.execPath, 'node' );
  //     test.true( _.strHas( op.output, `[ 'arg1' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath : 'node',
  //     args : 'arg1',
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath : testAppPath, args : 'arg2' })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.execPath, 'node' );
  //     test.true( _.strHas( op.output, `[ 'arg2' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath : 'node',
  //     args : [ 'arg1', 'arg2' ],
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath : testAppPath, args : 'arg3' })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.execPath, 'node' );
  //     test.true( _.strHas( op.output, `[ 'arg3' ]` ) );

  //     return op;
  //   })
  // })

  // .then( () =>
  // {
  //   var shell = _.process.starter
  //   ({
  //     execPath : 'node',
  //     args : 'arg1',
  //     outputCollecting : 1,
  //     outputPiping : 1
  //   })

  //   return shell({ execPath : testAppPath, args : [ 'arg2', 'arg3' ] })
  //   .then( ( op ) =>
  //   {
  //     test.identical( op.execPath, 'node' );
  //     test.true( _.strHas( op.output, `[ 'arg2', 'arg3' ]` ) );

  //     return op;
  //   })
  // })

  // return a.ready;

  /* - */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

function starterArgs( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    let starterOptions =
    {
      outputCollecting : 1,
      args : [ 'arg1', 'arg2' ],
      mode,
    }

    let shell = _.process.starter( starterOptions )

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath : path + ' arg3'`;

      return shell
      ({
        execPath : mode === 'fork' ? testAppPath + ' arg3' : 'node ' + testAppPath + ' arg3',
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        {
          test.identical( op.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
          test.identical( op.args2, [ testAppPath, 'arg3', '"arg1"', '"arg2"' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
          test.identical( op.args2, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else
        {
          test.identical( op.args, [ 'arg3', 'arg1', 'arg2' ] );
          test.identical( op.args2, [ 'arg3', 'arg1', 'arg2' ] );
          test.identical( starterOptions.args, [ 'arg3', 'arg1', 'arg2' ] );
        }
        test.identical( _.strCount( op.output, `[ 'arg3', 'arg1', 'arg2' ]` ), 1 );
        test.identical( starterOptions.args2, undefined );
        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath : path, args : [ ' arg3' ]`;

      return shell
      ({
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        args : [ 'arg3' ]
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        {
          test.identical( op.args, [ testAppPath, 'arg3' ] );
          test.identical( op.args2, [ testAppPath, '"arg3"' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ testAppPath, 'arg3' ] );
          test.identical( op.args2, [ testAppPath, 'arg3' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else
        {
          test.identical( op.args, [ 'arg3' ] );
          test.identical( op.args2, [ 'arg3' ] );
          test.identical( starterOptions.args, [ 'arg3', 'arg1', 'arg2' ] );
        }

        test.identical( _.strCount( op.output, `[ 'arg3' ]` ), 1 );
        test.identical( starterOptions.args2, undefined );
        return null;
      })
    });

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath : 'node', args : [ testAppPath, 'arg3' ]`;

      return shell
      ({
        execPath : mode === 'fork' ? '' : 'node',
        args : [ testAppPath, 'arg3' ]
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        {
          test.identical( op.args, [ testAppPath, 'arg3' ] );
          test.identical( op.args2, [ _.strQuote( testAppPath ), '"arg3"' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.args, [ testAppPath, 'arg3' ] );
          test.identical( op.args2, [ testAppPath, 'arg3' ] );
          test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
        }
        else
        {
          test.identical( op.args, [ 'arg3' ] );
          test.identical( op.args2, [ 'arg3' ] );
          test.identical( starterOptions.args, [ 'arg3', 'arg1', 'arg2' ] );
        }

        test.identical( _.strCount( op.output, `[ 'arg3' ]` ), 1 );
        test.identical( starterOptions.args2, undefined );
        return null;
      })
    })

    return ready;
  }

  /* ORIGINAL */
  // let starterOptions =
  // {
  //   outputCollecting : 1,
  //   args : [ 'arg1', 'arg2' ],
  //   mode : 'spawn',
  //   ready : a.ready
  // }

  // let shell = _.process.starter( starterOptions )

  // /* */

  // shell
  // ({
  //   execPath : 'node ' + testAppPath + ' arg3',
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( op.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
  //   test.identical( op.args2, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
  //   test.identical( _.strCount( op.output, `[ 'arg3', 'arg1', 'arg2' ]` ), 1 );
  //   // test.identical( starterOptions.args, [ 'arg1', 'arg2' ] );
  //   // test.identical( starterOptions.args2, [ 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args2, undefined );
  //   return null;
  // })

  // shell
  // ({
  //   execPath : 'node ' + testAppPath,
  //   args : [ 'arg3' ]
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( op.args, [ testAppPath, 'arg3' ] );
  //   test.identical( op.args2, [ testAppPath, 'arg3' ] );
  //   test.identical( _.strCount( op.output, `[ 'arg3' ]` ), 1 );
  //   // test.identical( starterOptions.args, [ 'arg1', 'arg2' ] );
  //   // test.identical( starterOptions.args2, [ 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args2, undefined );
  //   return null;
  // })

  // shell
  // ({
  //   execPath : 'node',
  //   args : [ testAppPath, 'arg3' ]
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( op.args, [ testAppPath, 'arg3' ] );
  //   test.identical( op.args2, [ testAppPath, 'arg3' ] );
  //   test.identical( _.strCount( op.output, `[ 'arg3' ]` ), 1 );
  //   // test.identical( starterOptions.args, [ 'arg1', 'arg2' ] );
  //   // test.identical( starterOptions.args2, [ 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args, [ testAppPath, 'arg3', 'arg1', 'arg2' ] );
  //   test.identical( starterOptions.args2, undefined );
  //   return null;
  // })

  // /* */

  // return a.ready;

  /* - */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

//

function starterFields( test )
{

  test.case = 'defaults';
  var start = _.process.starter();

  test.contains( _.mapKeys( start ), _.mapKeys( _.process.start ) );
  test.identical( _.mapKeys( start.defaults ), _.mapKeys( _.process.start.body.defaults ) );
  test.identical( start.head, _.process.start.head );
  test.identical( start.body, _.process.start.body );
  test.identical( _.mapKeys( start.predefined ), _.mapKeys( _.process.start.body.defaults ) );

  test.case = 'execPath';
  var start = _.process.starter( 'node -v' );
  test.contains( _.mapKeys( start ), _.mapKeys( _.process.start ) );
  test.identical( _.mapKeys( start.defaults ), _.mapKeys( _.process.start.body.defaults ) );
  test.identical( start.head, _.process.start.head );
  test.identical( start.body, _.process.start.body );
  test.identical( _.mapKeys( start.predefined ), _.mapKeys( _.process.start.body.defaults ) );
  test.identical( start.predefined.execPath, 'node -v' );

  test.case = 'object';
  var ready = new _.Consequence().take( null )
  var start = _.process.starter
  ({
    execPath : 'node -v',
    args : [ 'arg1', 'arg2' ],
    ready
  });
  test.contains( _.mapKeys( start ), _.mapKeys( _.process.start ) );
  test.identical( _.mapKeys( start.defaults ), _.mapKeys( _.process.start.body.defaults ) );
  test.identical( start.head, _.process.start.head );
  test.identical( start.body, _.process.start.body );
  test.true( _.arraySetIdentical( _.mapKeys( start.predefined ), _.mapKeys( _.process.start.body.defaults ) ) );
  test.identical( start.predefined.execPath, 'node -v' );
  test.identical( start.predefined.args, [ 'arg1', 'arg2' ] );
  test.identical( start.predefined.ready, ready  );
}

// --
// output
// --

function startMinimalOptionOutputCollecting( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => single( mode ) ) );
  return a.ready;

  /*  */

  function single( sync, deasync, mode )
  {
    let ready = new _.Consequence().take( null )

    if( sync && !deasync && mode === 'fork' )
    return null;

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:1`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputPiping : 1,
        outputCollecting : 1,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:0`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputPiping : 0,
        outputCollecting : 1,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:null`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputPiping : null,
        outputCollecting : 1,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:implicit`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:0 verbosity:0`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputPiping : 0,
        outputCollecting : 1,
        verbosity : 0,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:null verbosity:0`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputPiping : null,
        outputCollecting : 1,
        verbosity : 0,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode:${mode} outputPiping:implicit verbosity:0`;

      let o =
      {
        execPath : mode !== `fork` ? `node ${programPath}` : `${programPath}`,
        currentPath : a.abs( '.' ),
        outputCollecting : 1,
        verbosity : 0,
      }

      let returned = _.process.startMinimal( o );

      o.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'program1:begin\n' );
        return op;
      })

      return returned;
    })

    /* */

    return ready;
  }

  /*  */

  function program1()
  {
    console.log( 'program1:begin' );
  }

}

//

function startMinimalOptionOutputColoring( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 0, normal output, inputMirroring : 0`;

      let testAppPath2 = a.program( testApp2 );
      let locals = { programPath : testAppPath2, outputColoring : 0, inputMirroring : 0, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 1, normal output, inputMirroring : 0`;

      let testAppPath2 = a.program( testApp2 );
      let locals = { programPath : testAppPath2, outputColoring : 1, inputMirroring : 0, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        debugger;
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, '\u001b[35mLog\u001b[39;0m\n' )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 1, normal output, inputMirroring : 1`;

      let testAppPath2 = a.program( testApp2 );
      let locals = { programPath : testAppPath2, outputColoring : 1, inputMirroring : 1, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {

        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = `\u001b[97m > \u001b[39;0m${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\n\u001b[35mLog\u001b[39;0m\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 0, error output, inputMirroring : 0`;

      let testAppPath2 = a.program( testApp2Error );
      let locals = { programPath : testAppPath2, outputColoring : 0, inputMirroring : 0, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Error output\n' )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 1, error output, inputMirroring : 0`;

      let testAppPath2 = a.program( testApp2Error );
      let locals = { programPath : testAppPath2, outputColoring : 1, inputMirroring : 0, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, `\u001b[31mError output\u001b[39;0m\n` )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputColoring : 1, error output, inputMirroring : 1`;

      let testAppPath2 = a.program( testApp2Error );
      let locals = { programPath : testAppPath2, outputColoring : 1, inputMirroring : 1, mode };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = `\u001b[97m > \u001b[39;0m${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\n\u001b[31mError output\u001b[39;0m\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    })

    /* */

    return ready;
  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      throwingExitCode : 0,
      outputCollecting : 1,
      mode,
      inputMirroring,
      outputColoring,
    }

    return _.process.startMinimal( options );
  }

  function testApp2()
  {
    console.log( 'Log' );
  }

  function testApp2Error()
  {
    console.error( 'Error output' );
  }
}

startMinimalOptionOutputColoring.timeOut = 20e4; /* Locally : 19.079s */

//

function startMinimalOptionOutputColoringStderr( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColloring : { err : 0, out : 1 }, error output`;

      let testAppPath2 = a.program( testApp2Error );
      let locals =
      {
        programPath : testAppPath2,
        outputColoring : { err : 0, out : 1 },
        inputMirroring : 0,
        outputColoringStdout : null,
        mode,
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Error output\n' )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColoring : { err : 1, out : 1 }, error output`;

      let testAppPath2 = a.program( testApp2Error );
      let locals =
      {
        programPath : testAppPath2,
        outputColoring : { err : 1, out : 1 },
        inputMirroring : 0,
        outputColoringStdout : null,
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, `\u001b[31mError output\u001b[39;0m\n` )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, outputColoring : { err : 1, out : 1 }, error output`;

      let testAppPath2 = a.program( testApp2Error );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 1,
        outputColoring : { err : 1, out : 1 },
        outputColoringStdout : null,
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = `\u001b[97m > \u001b[39;0m${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\n\u001b[31mError output\u001b[39;0m\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, outputColoring : { err : 1, out : 0 }, error output`;

      let testAppPath2 = a.program( testApp2Error );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 1,
        outputColoring : { err : 1, out : 0 },
        outputColoringStdout : null,
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = ` > ${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\n\u001b[31mError output\u001b[39;0m\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColoring : { err : 1, out : 0 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 0,
        outputColoring : { err : 1, out : 0 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    return ready;

  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      throwingExitCode : 0,
      outputCollecting : 1,
      mode,
      inputMirroring,
      outputColoring
    }

    return _.process.startMinimal( options );
  }

  function testApp2Error()
  {
    console.error( 'Error output' );
  }

  function testApp2()
  {
    console.log( 'Log' );
  }
}

startMinimalOptionOutputColoringStderr.timeOut = 17e4; /* Locally : 16.099s */

//

function startMinimalOptionOutputColoringStdout( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColloring : { out : 0, err : 1 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 0,
        outputColoring : { out : 0, err : 1 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColoring : { out : 1, err : 0 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 0,
        outputColoring : { out : 1, err : 0 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, `\u001b[35mLog\u001b[39;0m\n` )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColoring : { out : 1, err : 1 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 0,
        outputColoring : { out : 1, err : 1 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, `\u001b[35mLog\u001b[39;0m\n` )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, outputColoring : { out : 1, err : 0 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 1,
        outputColoring : { out : 1, err : 0 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {

        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = `\u001b[97m > \u001b[39;0m${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\n\u001b[35mLog\u001b[39;0m\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0, outputColoring : { out : 1, err : 0 }, error output`;

      let testAppPath2 = a.program( testApp2Error );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 0,
        outputColoring : { out : 1, err : 0 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {

        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Error output\n' )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, outputColoring : { out : 0, err : 1 }, normal output`;

      let testAppPath2 = a.program( testApp2 );
      let locals =
      {
        programPath : testAppPath2,
        inputMirroring : 1,
        outputColoring : { out : 0, err : 1 },
        mode
      };
      let testAppPath = a.program({ routine : testApp, locals });

      let options =
      {
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {

        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let expected = ` > ${ mode === 'fork' ? '' : 'node ' }${testAppPath2}\nLog\n`;
        test.identical( op.output, expected )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );
        return null
      })
    } )

    return ready;

  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      throwingExitCode : 0,
      outputCollecting : 1,
      mode,
      inputMirroring,
      outputColoring
    }

    return _.process.startMinimal( options );
  }

  function testApp2()
  {
    console.log( 'Log' );
  }

  function testApp2Error()
  {
    console.error( 'Error output' );
  }

}

startMinimalOptionOutputColoringStdout.timeOut = 19e4; /* Locally : 18.513s */

//

function startMinimalOptionOutputGraying( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  /* */


  let modes = [ 'fork', 'spawn', 'shell' ];

  _.each( modes, ( mode ) =>
  {
    let execPath = testAppPath;
    if( mode !== 'fork' )
    execPath = 'node ' + execPath;

    _.process.startMinimal
    ({
      execPath,
      mode,
      outputGraying : 0,
      outputCollecting : 1,
      ready : a.ready
    })
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      let output = _.strSplitNonPreserving({ src : op.output, delimeter : '\n' });
      test.identical( output.length, 2 );
      test.identical( output[ 0 ], '\u001b[31m\u001b[43mColored message1\u001b[49;0m\u001b[39;0m' );
      test.identical( output[ 1 ], '\u001b[31m\u001b[43mColored message2\u001b[49;0m\u001b[39;0m' );
      return null;
    })

    _.process.startMinimal
    ({
      execPath,
      mode,
      outputGraying : 1,
      outputCollecting : 1,
      ready : a.ready
    })
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      let output = _.strSplitNonPreserving({ src : op.output, delimeter : '\n' });
      test.identical( output.length, 2 );
      test.identical( output[ 0 ], 'Colored message1' );
      test.identical( output[ 1 ], 'Colored message2' );
      return null;
    })
  })

  return a.ready;

  /* - */

  function testApp()
  {
    console.log( '\u001b[31m\u001b[43mColored message1\u001b[49;0m\u001b[39;0m' )
    console.log( '\u001b[31m\u001b[43mColored message2\u001b[49;0m\u001b[39;0m' )
  }
}

startMinimalOptionOutputGraying.timeOut = 15000;

//

function startMinimalOptionOutputPrefixing( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 0, coloring : 0, normal output`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        prefixing : 0,
        coloring : 0,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'Log\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 1, coloring : 0, normal output`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        prefixing : 1,
        coloring : 0,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, 'out : Log\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 0, coloring : 0, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        prefixing : 0,
        coloring : 0,
        programPath : testAppPath2,
        mode,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.strHas( op.output, 'err :' ) );
        test.true( _.strHas( op.output, 'randomText' ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 1, coloring : 0, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        prefixing : 1,
        coloring : 0,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, 'err :' ) );
        test.true( _.strHas( op.output, 'randomText' ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 0, coloring : 1, normal output`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        prefixing : 0,
        coloring : 1,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, '\u001b[35mLog\u001b[39;0m\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 1, coloring : 1, normal output`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        prefixing : 1,
        coloring : 1,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, '\u001b[37mout\u001b[39;0m\u001b[35m : Log\u001b[39;0m\n' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 0, coloring : 1, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        prefixing : 0,
        coloring : 1,
        programPath : testAppPath2,
        mode,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        let exp = `\u001b[31merr\u001b[39;0m\u001b[31m :`
        test.true( !_.strHas( op.output, exp ) );
        // debugger;
        let exp2 = `\u001b[31mrandomText\u001b[39;0m`.slice( 5, 15 );
        test.true( _.strHas( op.output, exp2 ) );
        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPrefixing : 1, coloring : 1, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        prefixing : 1,
        coloring : 1,
        programPath : testAppPath2,
        mode
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        // let exp = `\u001b[31merr :\u001b[39;0m`.slice( 5, 8 )
        let exp = `\u001b[31merr\u001b[39;0m\u001b[31m :`
        test.true( _.strHas( op.output, exp ) );
        let exp2 = `\u001b[31mrandomText\u001b[39;0m`.slice( 5, 15 );
        test.true( _.strHas( op.output, exp2 ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    return ready;

  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      mode,
      outputPrefixing : prefixing,
      inputMirroring : 0,
      outputPiping : 1,
      throwingExitCode : 0,
      outputColoring : coloring,
    }

    return _.process.startMinimal( options )
  }

  function testApp2()
  {
    console.log( 'Log' );
  }

  function testApp2Error()
  {
    randomText
  }
}

//

function startMinimalOptionOutputPiping( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode } outputPiping : 1, normal output`
      let testAppPath2 = a.program( { routine : testApp2, locals : { string : 'Log' } } );

      let locals =
      {
        piping : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
        prefixing : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'Log' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, normal output`
      let testAppPath2 = a.program( { routine : testApp2, locals : { string : 'Log' } } );

      let locals =
      {
        piping : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
        prefixing : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'Log' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, empty string, outputPiping : 1, outputPrefixing : 0, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : '' } });

      let locals =
      {
        piping : 1,
        prefixing : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, '' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, empty string, outputPiping : 1, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : '' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, 'out :' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, single line, outputPiping : 1, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : 'Log' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 1 );
        test.identical( _.strCount( op.output, 'Log' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 2 line output ( 1 with text ), outputPiping : 1, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : '\nLog' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 2 );
        test.identical( _.strCount( op.output, 'Log' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( 2 with text ), outputPiping : 1, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : '\nLog\nLog2\n' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 4 );
        test.identical( _.strCount( op.output, 'Log' ), 4 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 1, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 4 );
        test.identical( _.strCount( op.output, 'Log1' ), 2 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );
        test.identical( _.strCount( op.output, 'Log3' ), 2 );
        test.identical( _.strCount( op.output, 'Log4' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 1, outputPrefixing : 0, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 1,
        prefixing : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 2 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );
        test.identical( _.strCount( op.output, 'Log3' ), 2 );
        test.identical( _.strCount( op.output, 'Log4' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 0, outputPrefixing : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 1 );
        test.identical( _.strCount( op.output, 'Log2' ), 1 );
        test.identical( _.strCount( op.output, 'Log3' ), 1 );
        test.identical( _.strCount( op.output, 'Log4' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : null, outputPrefixing : 1, verbosity : 1, normal output`
      let testAppPath2 = a.program({ routine : testApp2, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : null,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 1,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 1 );
        test.identical( _.strCount( op.output, 'Log2' ), 1 );
        test.identical( _.strCount( op.output, 'Log3' ), 1 );
        test.identical( _.strCount( op.output, 'Log4' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : null, outputPrefixing : 1, verbosity : 1, normal output`
      let testAppPath2 = a.program( { routine : testApp2, locals : { string : 'Log' } } );

      let locals =
      {
        piping : null,
        verbosity : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out : Log' ), 0 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, outputPrefixing : 1, verbosity : 1, normal output`
      let testAppPath2 = a.program( { routine : testApp2, locals : { string : 'Log' } } );

      let locals =
      {
        piping : 1,
        verbosity : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out : Log' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, outputPrefixing : 1 , normal output`
      let testAppPath2 = a.program( { routine : testApp2, locals : { string : 'Log' } } );

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'out :' ), 0 );
        test.identical( _.strCount( op.output, 'Log' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
        prefixing : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'throw new Error()' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, verbosity : 1, error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 1,
        prefixing : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'throw new Error()' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
        prefixing : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'throw new Error()' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, outputPrefixing : 1 , error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strCount( op.output, 'err :' ) > 1 );
        test.identical( _.strCount( op.output, 'throw new Error()' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, outputPrefixing : 1 , error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'throw new Error()' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, empty string, outputPiping : 1, outputPrefixing : 0, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : '' } });

      let locals =
      {
        piping : 1,
        prefixing : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, '' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, empty string, outputPiping : 1, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : '' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, 'err :' );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, single line, outputPiping : 1, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : 'Log' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 1 );
        test.identical( _.strCount( op.output, 'Log' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 2 line output ( 1 with text ), outputPiping : 1, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : '\nLog' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 2 );
        test.identical( _.strCount( op.output, 'Log' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( 2 with text ), outputPiping : 1, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : '\nLog\nLog2\n' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 4 );
        test.identical( _.strCount( op.output, 'Log' ), 4 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 1, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 4 );
        test.identical( _.strCount( op.output, 'Log1' ), 2 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );
        test.identical( _.strCount( op.output, 'Log3' ), 2 );
        test.identical( _.strCount( op.output, 'Log4' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 1, outputPrefixing : 0, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 1,
        prefixing : 0,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 2 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );
        test.identical( _.strCount( op.output, 'Log3' ), 2 );
        test.identical( _.strCount( op.output, 'Log4' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : 0, outputPrefixing : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 1 );
        test.identical( _.strCount( op.output, 'Log2' ), 1 );
        test.identical( _.strCount( op.output, 'Log3' ), 1 );
        test.identical( _.strCount( op.output, 'Log4' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, 4 line output ( all with text ), outputPiping : null, outputPrefixing : 1, verbosity : 1, error output`
      let testAppPath2 = a.program({ routine : testApp2Error, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : null,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 1,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 1 );
        test.identical( _.strCount( op.output, 'Log2' ), 1 );
        test.identical( _.strCount( op.output, 'Log3' ), 1 );
        test.identical( _.strCount( op.output, 'Log4' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, outputPrefixing : 1, thrown error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strCount( op.output, 'err :' ) > 1 );
        test.identical( _.strCount( op.output, 'throw new Error();' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, outputPrefixing : 1, thrown error output`
      let testAppPath2 = a.program( testApp2Error2 );

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'throw new Error();' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 1, outputPrefixing : 1, error and normal output`
      let testAppPath2 = a.program({ routine : testAppNormalAndError, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 1,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 1 );
        test.identical( _.strCount( op.output, 'out :' ), 4 );
        test.identical( _.strCount( op.output, 'Log1' ), 2 );
        test.identical( _.strCount( op.output, 'Log2' ), 2 );
        test.identical( _.strCount( op.output, 'Error output' ), 2 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, outputPiping : 0, outputPrefixing : 1, error and normal output`
      let testAppPath2 = a.program({ routine : testAppNormalAndError, locals : { string : 'Log1\nLog2\nLog3\nLog4' } });

      let locals =
      {
        piping : 0,
        prefixing : 1,
        programPath : testAppPath2,
        mode,
        verbosity : 2,
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( _.strCount( op.output, 'err :' ), 0 );
        test.identical( _.strCount( op.output, 'out :' ), 0 );
        test.identical( _.strCount( op.output, 'Log1' ), 1 );
        test.identical( _.strCount( op.output, 'Log2' ), 1 );
        test.identical( _.strCount( op.output, 'Error output' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })

    })

    return ready;
  }

  /* */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      mode,
      inputMirroring : 0,
      outputPiping : piping,
      verbosity,
      outputCollecting : 1,
      throwingExitCode : 0,
      outputColoring : 0,
      outputPrefixing : prefixing
    }

    return _.process.startMinimal( options )
    .then( ( op ) =>
    {
      console.log( op.output );
      return null;
    } )
  }

  function testApp2Error2()
  {
    throw new Error();
  }

  function testApp2Error()
  {
    console.error( string );
  }

  function testApp2()
  {
    console.log( string );
  }

  function testAppNormalAndError()
  {
    console.log( '\nLog1\nLog2\n' );
    console.error( 'Error output' );
  }

}

startMinimalOptionOutputPiping.timeOut = 3e5;

//

function startMinimalOptionInputMirroring( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 0`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 0,
        verbosity : 2
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.strHas( op.output, testAppPath2 ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 1,
        outputPiping : 1,
        verbosity : 2
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, testAppPath2 ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, verbosity : 0`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 1,
        verbosity : 0
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.strHas( op.output, testAppPath2 ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, verbosity : 1`;

      let testAppPath2 = a.program( testApp2 );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 1,
        verbosity : 1
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, testAppPath2 ) );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 1,
        verbosity : 2
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, testAppPath2 ) );
        test.true( _.strHas( op.output, 'throw new Error();' ) )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, inputMirroring : 1, verbosity : 1, error output`;

      let testAppPath2 = a.program( testApp2Error );

      let locals =
      {
        programPath : testAppPath2,
        mode,
        inputMirroring : 1,
        verbosity : 1
      }

      let testAppPath = a.program({ routine : testApp, locals });

      return _.process.startMinimal
      ({
        execPath : 'node ' + testAppPath,
        outputCollecting : 1,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( _.strHas( op.output, testAppPath2 ) );
        test.true( !_.strHas( op.output, 'throw new Error();' ) )

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      })
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      mode,
      inputMirroring,
      verbosity,
      outputCollecting : 1,
      throwingExitCode : 0,
    }

    return _.process.startMinimal( options )

  }

  function testApp2Error()
  {
    throw new Error();
  }

  function testApp2()
  {
    console.log( 'Log' );
  }
}

//

function startMinimalOptionLogger( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];

  /* */

  test.case = 'custom logger with increased level'

  _.each( modes, ( mode ) =>
  {
    let execPath = testAppPath;
    if( mode !== 'fork' )
    execPath = 'node ' + execPath;

    let loggerOutput = '';

    let logger = new _.Logger({ output : null, onTransformEnd });
    logger.up();

    _.process.startMinimal
    ({
      execPath,
      mode,
      outputCollecting : 1,
      outputPiping : 1,
      outputColoring : 0,
      logger,
      ready : a.ready,
    })
    .then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      test.true( _.strHas( op.output, '  One tab' ) );
      test.true( _.strHas( loggerOutput, '    One tab' ) );
      console.log( 'loggerOutput', loggerOutput );
      return null;
    })

    /*  */

    function onTransformEnd( o )
    {
      loggerOutput += o.outputForPrinter[ 0 ] + '\n';
    }
  })

  /* */

  return a.ready;

  /* - */

  function testApp()
  {
    console.log( '  One tab' );
  }
}

//

function startMinimalOptionLoggerTransofrmation( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  /* */

  let modes = [ 'fork', 'spawn', 'shell' ];
  var loggerOutput = '';

  var logger = new _.Logger({ output : null, onTransformEnd });

  modes.forEach( ( mode ) =>
  {
    let path = testAppPath;
    if( mode !== 'fork' )
    path = 'node ' + path;

    console.log( mode )

    a.ready.then( () =>
    {
      loggerOutput = '';
      var o = { execPath : path, mode, outputPiping : 0, outputCollecting : 0, logger };
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.output, null );
        test.true( !_.strHas( loggerOutput, 'testApp-output') );
        console.log( loggerOutput )
        return true;
      })
    })

    a.ready.then( () =>
    {
      loggerOutput = '';
      var o = { execPath : path, mode, outputPiping : 1, outputCollecting : 0, logger };
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.output, null );
        test.true( _.strHas( loggerOutput, 'testApp-output') );
        return true;
      })
    })

    a.ready.then( () =>
    {
      loggerOutput = '';
      var o = { execPath : path, mode, outputPiping : 0, outputCollecting : 1, logger };
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.output, 'testApp-output\n\n' );
        test.true( !_.strHas( loggerOutput, 'testApp-output') );
        return true;
      })
    })

    a.ready.then( () =>
    {
      loggerOutput = '';
      var o = { execPath : path, mode, outputPiping : 1, outputCollecting : 1, logger };
      return _.process.startMinimal( o )
      .then( () =>
      {
        test.identical( o.output, 'testApp-output\n\n' );
        test.true( _.strHas( loggerOutput, 'testApp-output') );
        return true;
      })
    })
  })

  return a.ready;

  function onTransformEnd( o )
  {
    loggerOutput += o.outputForPrinter[ 0 ];
  }

  function testApp()
  {
    console.log( 'testApp-output\n' );
  }
}

//

function startMinimalOutputOptionsCompatibilityLateCheck( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let testAppPathParent = a.program( testAppParent );

  if( !Config.debug )
  {
    test.identical( 1, 1 );
    return;
  }

  let modes = [ 'spawn', 'fork', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  })

  return a.ready;

  /* */

  function run( mode )
  {
    let commonOptions =
    {
      execPath : mode === 'fork' ? 'testApp.js' : 'node testApp.js',
      mode,
      currentPath : a.routinePath,
    }

    let ready = _.Consequence().take( null )

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 0, stdio : 'ignore'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 0,
        stdio : 'ignore',
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 0, stdio : 'ignore'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 0,
        stdio : 'ignore',
      }
      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 1, stdio : 'ignore'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 1,
        stdio : 'ignore',
      }
      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : 'ignore'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : 'ignore',
      }
      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 0, stdio : 'pipe'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 0,
        stdio : 'pipe',
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 0, stdio : 'pipe'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 0,
        stdio : 'pipe',
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 1, stdio : 'pipe'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 1,
        stdio : 'pipe',
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : 'pipe'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : 'pipe',
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 0, stdio : 'inherit'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 0,
        stdio : 'inherit',
      }

      _.mapExtend( o, commonOptions );

      let o2 =
      {
        execPath : 'node testAppParent.js',
        mode : 'spawn',
        ipc : 1,
        currentPath : a.routinePath,
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1
      }

      _.process.startMinimal( o2 );

      o2.conStart.thenGive( () => o2.pnd.send( o ) );

      o2.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        return null;
      })

      return o2.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 0, stdio : 'inherit'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 0,
        stdio : 'inherit',
      }

      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 0, outputCollecting : 1, stdio : 'inherit'`;
      let o =
      {
        outputPiping : 0,
        outputCollecting : 1,
        stdio : 'inherit',
      }

      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : 'inherit'`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : 'inherit',
      }

      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'ignore', 'ignore' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'ignore', 'ignore', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'inherit', 'inherit', 'inherit' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'inherit', 'inherit', 'inherit', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      return test.shouldThrowErrorSync(  () => _.process.startMinimal( o ) );
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'pipe', 'pipe', 'pipe' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'pipe', 'pipe', 'pipe', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'pipe', 'ignore' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'pipe', 'ignore', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'ignore', 'pipe' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'ignore', 'pipe', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( !_.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'pipe', 'inherit' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'pipe', 'inherit', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'inherit', 'pipe' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'inherit', 'pipe', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      let o2 =
      {
        execPath : 'node testAppParent.js',
        mode : 'spawn',
        ipc : 1,
        currentPath : a.routinePath,
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1
      }

      _.process.startMinimal( o2 );

      o2.conStart.thenGive( () => o2.pnd.send( o ) );

      o2.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o2.conTerminate;
    })

    /* */

    .then( () =>
    {
      test.case = `outputPiping : 1, outputCollecting : 1, stdio : [ 'ignore', 'pipe', 'pipe' ]`;
      let o =
      {
        outputPiping : 1,
        outputCollecting : 1,
        stdio : [ 'ignore', 'pipe', 'pipe', mode === 'fork' ? 'ipc' : null ],
      }

      _.mapExtend( o, commonOptions );

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.true( _.strHas( op.output, 'Test output' ) );
        return null;
      })

      return o.conTerminate;
    })

    return ready;
  }

  /* */

  function testApp()
  {
    let _ = require( toolsPath );
    console.log( 'Test output' );
  }

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let ready = new _.Consequence();

    process.on( 'message', ( op ) =>
    {
      ready.take( op );
      process.disconnect();
    })

    ready.then( ( op ) => _.process.startMinimal( op ) );
  }
}

//

function startMinimalOptionVerbosity( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let capturedOutput;
  let captureLogger = new _.Logger({ output : null, onTransformEnd, raw : 1 })
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}, verbosity : 0`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log('message')"`,
        mode,
        verbosity : 0,
        outputPiping : null,
        outputCollecting : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( capturedOutput, '' );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, verbosity : 1`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log('message')"`,
        mode,
        verbosity : 1,
        outputPiping : null,
        outputCollecting : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        test.identical( _.strCount( capturedOutput, `node -e "console.log('message')"`), 1 );
        else if( mode === 'spawn' )
        test.identical( _.strCount( capturedOutput, `node -e console.log('message')`), 1 );
        else
        test.identical( _.strCount( capturedOutput, `-e console.log('message')`), 1 );
        test.identical( _.strCount( capturedOutput, 'message' ), 1 );
        test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, verbosity : 2`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log('message')"`,
        mode,
        verbosity : 2,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        test.identical( _.strCount( capturedOutput, `node -e "console.log('message')"`), 1 );
        else if( mode === 'spawn' )
        test.identical( _.strCount( capturedOutput, `node -e console.log('message')`), 1 );
        else
        test.identical( _.strCount( capturedOutput, `-e console.log('message')`), 1 );
        test.identical( _.strCount( capturedOutput, 'message' ), 2 );
        test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, verbosity : 3`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log('message')"`,
        mode,
        verbosity : 3,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        test.identical( _.strCount( capturedOutput, `node -e "console.log('message')"`), 1 );
        else if( mode === 'spawn' )
        test.identical( _.strCount( capturedOutput, `node -e console.log('message')`), 1 );
        else
        test.identical( _.strCount( capturedOutput, `-e console.log('message')`), 1 );
        test.identical( _.strCount( capturedOutput, 'message' ), 2 );
        test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 1 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, verbosity : 5`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log('message')"`,
        mode,
        verbosity : 5,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        test.identical( _.strCount( capturedOutput, `node -e "console.log('message')"`), 1 );
        else if( mode === 'spawn' )
        test.identical( _.strCount( capturedOutput, `node -e console.log('message')`), 1 );
        else
        test.identical( _.strCount( capturedOutput, `-e console.log('message')`), 1 );
        test.identical( _.strCount( capturedOutput, 'message' ), 2 );
        test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 1 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, error, verbosity : 0`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "process.exit(1)"`,
        mode,
        verbosity : 0,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );
        test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, error, verbosity : 1`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "process.exit(1)"`,
        mode,
        verbosity : 1,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );
        test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, error, verbosity : 2`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "process.exit(1)"`,
        mode,
        verbosity : 2,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );
        test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, error, verbosity : 3`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "process.exit(1)"`,
        mode,
        verbosity : 3,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );
        test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, error, verbosity : 5`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "process.exit(1)"`,
        mode,
        verbosity : 5,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 0,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );
        test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 1 );
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath has quotes, verbosity : 1`;
      capturedOutput = '';

      return _.process.startMinimal
      ({
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log( 'a', 'b', \`c\` )"`,
        mode,
        verbosity : 1,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 1,
        logger : captureLogger,
      })
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'shell' )
        {
          test.identical( op.fullExecPath, `node -e "console.log( 'a', 'b', \`c\` )"` );
          test.identical( _.strCount( capturedOutput, `node -e "console.log( 'a', 'b', \`c\` )"` ), 1 );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.fullExecPath, `node -e console.log( 'a', 'b', \`c\` )` );
          test.identical( _.strCount( capturedOutput, `node -e console.log( 'a', 'b', \`c\` )` ), 1 );
        }
        else
        {
          test.identical( op.fullExecPath, `-e console.log( 'a', 'b', \`c\` )` );
          test.identical( _.strCount( capturedOutput, `-e console.log( 'a', 'b', \`c\` )` ), 1 );
        }
        return true;
      })
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath has double quotes, verbosity : 1`;
      capturedOutput = '';

      let options =
      {
        execPath : `${mode === 'fork' ? '' : 'node' } -e "console.log( '"a"', "'b'", \`"c"\` )"`,
        mode,
        verbosity : 1,
        stdio : 'pipe',
        outputPiping : null,
        outputCollecting : 0,
        outputColoring : 0,
        throwingExitCode : 1,
        logger : captureLogger,
      }

      /* in mode::shell on Linux and iOS
        -> Stderr
          -  sh: c: command not found
          -  [eval]:1
          -  console.log( 'a', b,  )
      */
      if( mode === 'shell' && process.platform !== 'win32' )
      return test.shouldThrowErrorAsync( () => _.process.startMinimal( options ) );

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        if( mode === 'fork' )
        {
          test.identical( op.fullExecPath, `-e console.log( '"a"', "'b'", \`"c"\` )` );
          test.identical( _.strCount( capturedOutput, `-e console.log( '"a"', "'b'", \`"c"\` )` ), 1 );
        }
        else if( mode === 'spawn' )
        {
          test.identical( op.fullExecPath, `node -e console.log( '"a"', "'b'", \`"c"\` )` );
          test.identical( _.strCount( capturedOutput, `node -e console.log( '"a"', "'b'", \`"c"\` )` ), 1 );
        }
        else
        {
          test.identical( op.fullExecPath, `node -e "console.log( '"a"', "'b'", \`"c"\` )"` );
          test.identical( _.strCount( capturedOutput, `node -e "console.log( '"a"', "'b'", \`"c"\` )"` ), 1 );
        }
        return true;
      })
    })

    return ready;

  }

  /* ORIGINAL */
  // testCase( 'verbosity : 0' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log('message')"`,
  //   mode : 'spawn',
  //   verbosity : 0,
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( capturedOutput, '' );
  //   return true;
  // })

  // /* */

  // testCase( 'verbosity : 1' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log('message')"`,
  //   mode : 'spawn',
  //   verbosity : 1,
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   console.log( capturedOutput )
  //   test.identical( _.strCount( capturedOutput, `node -e console.log('message')`), 1 );
  //   test.identical( _.strCount( capturedOutput, 'message' ), 1 );
  //   test.identical( _.strCount( capturedOutput, 'at ' + _.path.current() ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'verbosity : 2' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log('message')"`,
  //   mode : 'spawn',
  //   verbosity : 2,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, `node -e console.log('message')` ), 1 );
  //   test.identical( _.strCount( capturedOutput, 'message' ), 2 );
  //   test.identical( _.strCount( capturedOutput, 'at ' + _.path.current() ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'verbosity : 3' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log('message')"`,
  //   mode : 'spawn',
  //   verbosity : 3,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, `node -e console.log('message')` ), 1 );
  //   test.identical( _.strCount( capturedOutput, 'message' ), 2 );
  //   test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 1 );
  //   return true;
  // })

  // /* */

  // testCase( 'verbosity : 5' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log('message')"`,
  //   mode : 'spawn',
  //   verbosity : 5,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, `node -e console.log('message')` ), 1 );
  //   test.identical( _.strCount( capturedOutput, 'message' ), 2 );
  //   test.identical( _.strCount( capturedOutput, '@ ' + _.path.current() ), 1 );
  //   return true;
  // })

  // /* */

  // testCase( 'error, verbosity : 0' )
  // _.process.start
  // ({
  //   execPath : `node -e "process.exit(1)"`,
  //   mode : 'spawn',
  //   verbosity : 0,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 1 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'error, verbosity : 1' )
  // _.process.start
  // ({
  //   execPath : `node -e "process.exit(1)"`,
  //   mode : 'spawn',
  //   verbosity : 1,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 1 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'error, verbosity : 2' )
  // _.process.start
  // ({
  //   execPath : `node -e "process.exit(1)"`,
  //   mode : 'spawn',
  //   verbosity : 2,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 1 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'error, verbosity : 3' )
  // _.process.start
  // ({
  //   execPath : `node -e "process.exit(1)"`,
  //   mode : 'spawn',
  //   verbosity : 3,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 1 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 0 );
  //   return true;
  // })

  // /* */

  // testCase( 'error, verbosity : 5' )
  // _.process.start
  // ({
  //   execPath : `node -e "process.exit(1)"`,
  //   mode : 'spawn',
  //   verbosity : 5,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 0,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 1 );
  //   test.identical( op.ended, true );
  //   test.identical( _.strCount( capturedOutput, 'Process returned error code ' + op.exitCode ), 1 );
  //   return true;
  // })

  // /* */

  // testCase( 'execPath has quotes, verbosity : 1' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log( \"a\", 'b', \`c\` )"`,
  //   mode : 'spawn',
  //   verbosity : 5,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 1,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( op.fullExecPath, `node -e console.log( \"a\", 'b', \`c\` )` );
  //   test.identical( _.strCount( capturedOutput, `node -e console.log( \"a\", 'b', \`c\` )` ), 1 );
  //   return true;
  // })

  // /* */

  // testCase( 'execPath has double quotes, verbosity : 1' )
  // _.process.start
  // ({
  //   execPath : `node -e "console.log( '"a"', "'b'", \`"c"\` )"`,
  //   mode : 'spawn',
  //   verbosity : 5,
  //   stdio : 'pipe',
  //   outputPiping : null,
  //   outputCollecting : 0,
  //   throwingExitCode : 1,
  //   outputColoring : 0,
  //   logger : captureLogger,
  //   ready : a.ready
  // })
  // .then( ( op ) =>
  // {
  //   test.identical( op.exitCode, 0 );
  //   test.identical( op.ended, true );
  //   test.identical( op.fullExecPath, `node -e console.log( '"a"', "'b'", \`"c"\` )` );
  //   test.identical( _.strCount( capturedOutput, `node -e console.log( '"a"', "'b'", \`"c"\` )` ), 1 );
  //   return true;
  // })

  // return a.ready;

  // /*  */

  // function testCase( src )
  // {
  //   a.ready.then( () =>
  //   {
  //     capturedOutput = '';
  //     test.case = src;
  //     return null
  //   });
  // }

  function onTransformEnd( o )
  {
    capturedOutput += o.outputForPrinter[ 0 ] + '\n';
  }

}

// --
// etc
// --

function appTempApplication( test )
{
  let context = this;

  /* */

  function testApp()
  {
    console.log( process.argv.slice( 2 ) );
  }

  let testAppCode = testApp.toString() + '\ntestApp();';

  /* */

  test.case = 'string';
  var returned = _.process.tempOpen( testAppCode );
  var read = _.fileProvider.fileRead( returned );
  test.identical( read, testAppCode );
  _.process.tempClose( returned );
  test.true( !_.fileProvider.fileExists( returned ) );

  /* */

  test.case = 'string';
  var returned = _.process.tempOpen({ sourceCode : testAppCode });
  var read = _.fileProvider.fileRead( returned );
  test.identical( read, testAppCode );
  _.process.tempClose( returned );
  test.true( !_.fileProvider.fileExists( returned ) );

  /* */

  test.case = 'raw buffer';
  var returned = _.process.tempOpen( _.bufferRawFrom( testAppCode ) );
  var read = _.fileProvider.fileRead( returned );
  test.identical( read, testAppCode );
  _.process.tempClose( returned );
  test.true( !_.fileProvider.fileExists( returned ) );

  /* */

  test.case = 'raw buffer';
  var returned = _.process.tempOpen({ sourceCode : _.bufferRawFrom( testAppCode ) });
  var read = _.fileProvider.fileRead( returned );
  test.identical( read, testAppCode );
  _.process.tempClose( returned );
  test.true( !_.fileProvider.fileExists( returned ) );

  /* */

  test.case = 'remove all';
  var returned1 = _.process.tempOpen( testAppCode );
  var returned2 = _.process.tempOpen( testAppCode );
  test.true( _.fileProvider.fileExists( returned1 ) );
  test.true( _.fileProvider.fileExists( returned2 ) );
  _.process.tempClose();
  test.true( !_.fileProvider.fileExists( returned1 ) );
  test.true( !_.fileProvider.fileExists( returned2 ) );
  test.mustNotThrowError( () => _.process.tempClose() )

  if( !Config.debug )
  return;

  test.case = 'unexpected type of sourceCode option';
  test.shouldThrowErrorSync( () =>
  {
    _.process.tempOpen( [] );
  })

  /* */

  test.case = 'unexpected option';
  test.shouldThrowErrorSync( () =>
  {
    _.process.tempOpen({ someOption : true });
  })

  /* */

  test.case = 'try to remove file that does not exist in registry';
  var returned = _.process.tempOpen( testAppCode );
  _.process.tempClose( returned );
  test.shouldThrowErrorSync( () =>
  {
    _.process.tempClose( returned );
  })
}

// --
// other options
// --

function startMinimalOptionStreamSizeLimit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) )
    a.ready.then( () => run( mode ) )
    a.ready.tap( () => test.close( mode ) )
  })

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.take( null );

    ready.then( () =>
    {
      test.case = `data is less than streamSizeLimit ( default )`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        outputCollecting : 1,
      }

      let returned =  _.process.startMinimal( options );
      test.identical( returned.pnd.stdout.toString(), 'data1\n' );

      a.fileProvider.fileDelete( testAppPath );

      return returned;

    });

    /* */

    ready.then( () =>
    {
      test.case = `data is less than streamSizeLimit ( 20 )`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        streamSizeLimit : 20,
        outputCollecting : 1,
      }

      let returned =  _.process.startMinimal( options );
      test.identical( returned.pnd.stdout.toString(), 'data1\n' );

      a.fileProvider.fileDelete( testAppPath );

      return returned;

    });

    /* */

    ready.then( () =>
    {
      test.case = `data is equal to the streamSizeLimit`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        streamSizeLimit : 10,
        outputCollecting : 1,
      }

      let returned =  _.process.startMinimal( options );
      test.identical( returned.pnd.stdout.toString(), 'data1\n' )

      a.fileProvider.fileDelete( testAppPath );
      return returned;

    });

    /* */

    ready.then( () =>
    {
      test.case = `data is bigger than streamSizeLimit`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        streamSizeLimit : 4,
        outputCollecting : 1,
      }

      let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, `code : 'ENOBUFS'`) )

      test.notIdentical( options.exitCode, 0 );

      a.fileProvider.fileDelete( testAppPath );
      return null;

    });

    return ready;
  }

  /* - */

  function testApp()
  {
    console.log( 'data1' );
  }
}

//

function startMinimalOptionStreamSizeLimitThrowing( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'spawn', 'shell' ];

  a.ready.then( () =>
  {
    test.case = `mode : 'fork', deasync : 1, limit : 100`;

    let testAppPath = a.program( testApp );

    let options =
    {
      execPath : 'node ' + testAppPath,
      mode : 'fork',
      deasync : 1,
      streamSizeLimit : 100,
      outputCollecting : 1,
    }

    let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

    test.true( _.errIs( returned ) );
    test.true( _.strHas( returned.message, `Option::streamSizeLimit is supported in mode::spawn and mode::shell with sync::1` ) )

    test.notIdentical( options.exitCode, 0 );

    a.fileProvider.fileDelete( testAppPath );

    return null;
  } )

  /* */

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) )
    a.ready.then( () => run( mode ) )
    a.ready.tap( () => test.close( mode ) )
  })

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.take( null );

    /* */

    ready.then( () =>
    {
      test.case = `sync : 1, limit : '100'`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        streamSizeLimit : '100',
        outputCollecting : 1,
      }

      let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, `Option::streamSizeLimit must be a positive Number which is greater than zero` ) )

      test.notIdentical( options.exitCode, 0 );

      a.fileProvider.fileDelete( testAppPath );
      return null;

    });

    /* */

    ready.then( () =>
    {
      test.case = `sync : 1, limit : -1`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 1,
        streamSizeLimit : -1,
        outputCollecting : 1,
      }

      let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, `Option::streamSizeLimit must be a positive Number which is greater than zero` ) )

      test.notIdentical( options.exitCode, 0 );

      a.fileProvider.fileDelete( testAppPath );
      return null;

    });

    /* */

    ready.then( () =>
    {
      test.case = `sync : 0, limit : 100`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 0,
        streamSizeLimit : 100,
        outputCollecting : 1,
      }

      let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, `Option::streamSizeLimit is supported in mode::spawn and mode::shell with sync::1` ) )

      test.notIdentical( options.exitCode, 0 );

      a.fileProvider.fileDelete( testAppPath );
      return null;

    });

    /* */

    ready.then( () =>
    {
      test.case = `sync : 0, deasync : 1, limit : 100`;

      let testAppPath = a.program( testApp );

      let options =
      {
        execPath : 'node ' + testAppPath,
        mode,
        sync : 0,
        deasync : 1,
        streamSizeLimit : 100,
        outputCollecting : 1,
      }

      let returned = test.shouldThrowErrorSync( () => _.process.startMinimal( options ) )

      test.true( _.errIs( returned ) );
      test.true( _.strHas( returned.message, `Option::streamSizeLimit is supported in mode::spawn and mode::shell with sync::1` ) )

      test.notIdentical( options.exitCode, 0 );

      a.fileProvider.fileDelete( testAppPath );
      return null;

    });

    return ready;
  }

  /* - */

  function testApp()
  {
    console.log( 'data1' );
  }
}

//

function startSingleOptionDry( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 0, deasync : 0 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 0, deasync : 1 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 1, deasync : 0 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 1, deasync : 1 }) ) );
  return a.ready;

  function run( tops )
  {
    let ready = new _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startSingle
      ({
        execPath : programPath + ` arg1`,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      })
    });

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, dry : 1, no error`
      let o =
      {
        execPath : tops.mode === 'fork' ? programPath + ` arg1` : 'node ' + programPath + ` arg1`,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : [ 'arg0' ],
        dry : 1,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 1,
        applyingExitCode : 1,
        ipc : tops.mode === 'shell' ? 0 : 1,
        when : { delay : context.t1 * 2 }, /* 2000 */
      }
      let track = [];
      var t1 = _.time.now();
      var returned = _.process.startSingle( o );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.true( returned === o );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      o.conStart.tap( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.pnd, null );
        return null;
      })

      o.conDisconnect.tap( ( err, op ) =>
      {
        track.push( 'conDisconnect' );
        test.identical( err, _.dont );
        test.identical( op, undefined );
        test.identical( o.pnd, null );
        return null;
      })

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.pnd, null );
        return null;
      })

      o.ready.tap( ( err, op ) =>
      {
        var t2 = _.time.now();
        test.ge( t2 - t1, context.t1 * 2 ); /* 2000 */
        track.push( 'ready' );
        test.identical( o.pnd, null );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( op.procedure._name, null );
        test.identical( op.procedure._object, null );
        test.identical( op.state, 'terminated' );
        test.identical( op.exitReason, null );
        test.identical( op.exitCode, null );
        test.identical( op.exitSignal, null );
        test.identical( op.error, null );
        test.identical( op.pnd, null );
        test.identical( op.output, '' );
        test.identical( op.ended, true );
        test.identical( op.streamOut, null );
        test.identical( op.streamErr, null );

        /* qqq for Yevhen : bad */
        if ( tops.mode === 'shell' )
        {
          test.identical( op.stdio, [ 'pipe', 'pipe', 'pipe' ] );
          test.identical( op.fullExecPath, `node ${programPath} arg1 "arg0"` );
        }
        else
        {
          test.identical( op.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
          if( tops.mode === 'fork' )
          test.identical( op.fullExecPath, `${programPath} arg1 arg0` );
          else
          test.identical( op.fullExecPath, `node ${programPath} arg1 arg0` );
        }

        test.true( !a.fileProvider.fileExists( a.path.join( a.routinePath, 'file' ) ) )
        if( tops.deasync || tops.sync )
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate', 'ready' ] );
        else
        test.identical( track, [ 'conStart', 'conTerminate', 'conDisconnect', 'ready' ] );
        return null;
      })

      return null;
    })


    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, dry : 1, wrong execPath`;
      let o =
      {
        execPath : 'err ' + programPath + ' arg1',
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : [ 'arg0' ],
        dry : 1,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 1,
        applyingExitCode : 1,
        ipc : tops.mode === 'shell' ? 0 : 1,
        when : { delay : context.t1 * 2 }, /* 2000 */
      }
      let track = [];
      var t1 = _.time.now();
      var returned = _.process.startSingle( o );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
        test.true( returned === o );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      o.conStart.tap( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.pnd, null );
        return null;
      })

      o.conDisconnect.tap( ( err, op ) =>
      {
        track.push( 'conDisconnect' );
        test.identical( err, _.dont );
        test.identical( op, undefined );
        test.identical( o.pnd, null );
        return null;
      })

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( o.pnd, null );
        return null;
      })

      o.ready.tap( ( err, op ) =>
      {
        var t2 = _.time.now();
        test.ge( t2 - t1, context.t1 * 2 ); /* 2000 */
        track.push( 'ready' );
        test.identical( o.pnd, null );
        test.identical( err, undefined );
        test.identical( op, o );
        test.identical( op.procedure._name, null );
        test.identical( op.procedure._object, null );
        test.identical( op.state, 'terminated' );
        test.identical( op.exitReason, null );
        test.identical( op.exitCode, null );
        test.identical( op.exitSignal, null );
        test.identical( op.error, null );
        test.identical( op.pnd, null );
        test.identical( op.output, '' );
        test.identical( op.ended, true );
        test.identical( op.streamOut, null );
        test.identical( op.streamErr, null );
        if ( tops.mode === 'shell' )
        {
          test.identical( op.stdio, [ 'pipe', 'pipe', 'pipe' ] );
          test.identical( op.fullExecPath, `err ${programPath} arg1 "arg0"` );
        }
        else
        {
          test.identical( op.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
          test.identical( op.fullExecPath, `err ${programPath} arg1 arg0` );
        }

        test.true( !a.fileProvider.fileExists( a.path.join( a.routinePath, 'file' ) ) )
        if( tops.deasync || tops.sync )
        test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate', 'ready' ] );
        else
        test.identical( track, [ 'conStart', 'conTerminate', 'conDisconnect', 'ready' ] );
        return null;
      })

      return null;
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    var fs = require( 'fs' );
    var path = require( 'path' );
    var filePath = path.join( __dirname, 'file' );
    fs.writeFileSync( filePath, filePath );
  }
}

startSingleOptionDry.rapidity = -1;
startSingleOptionDry.timeOut = 5e5;
startSingleOptionDry.description =
`
Simulates run of routine start with all possible options.
After execution checks fields of run descriptor.
`

//

function startMultipleOptionDry( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let track = [];

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 0, deasync : 0 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 0, deasync : 1 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 1, deasync : 0 }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ mode, sync : 1, deasync : 1 }) ) );
  return a.ready;

  function run( tops )
  {
    let ready = new _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startMultiple
      ({
        execPath : [ programPath + ` id:1`, programPath + ` id:2` ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      })
    });

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync :${tops.deasync}, dry : 1, without error, con* checks`;

      let options =
      {
        execPath : [ tops.mode === 'fork' ? programPath + ' id:1' : 'node ' + programPath + ' id:1', tops.mode === 'fork' ? programPath + ' id:2' : 'node ' + programPath + ' id:2' ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        outputCollecting : 1,
        dry : 1
      }

      let returned = _.process.startMultiple( options )

      test.identical( options.procedure._name, null );
      test.identical( options.state, 'terminated' );
      test.identical( options.exitReason, 'normal' );
      test.identical( options.exitCode, null );
      test.identical( options.exitSignal, null );
      test.identical( options.error, null );
      test.identical( options.pnd, undefined );
      test.identical( options.output, '' );
      test.identical( options.ended, true );
      if( tops.sync && !tops.deasync )
      {
        test.true( !_.streamIs( options.streamOut ) );
        test.true( !_.streamIs( options.streamErr ) );
      }
      else
      {
        test.true( _.streamIs( options.streamOut ) );
        test.true( _.streamIs( options.streamErr ) );
      }
      if( tops.mode === 'fork' )
      {
        test.identical( options.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
      }
      else
      {
        test.identical( options.stdio, [ 'pipe', 'pipe', 'pipe' ] );
      }

      options.sessions.forEach( ( op2, counter ) =>
      {
        op2.conStart.tap( ( err, op ) =>
        {
          track.push( 'conStart' );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.process, null );
          return null;
        })

        op2.conDisconnect.tap( ( err, op ) =>
        {
          track.push( 'conDisconnect' );
          test.identical( err, _.dont );
          test.identical( op, undefined );
          test.identical( op2.process, null );
          return null;
        })

        op2.conTerminate.tap( ( err, op ) =>
        {
          track.push( 'conTerminate' );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.process, null );
          return null;
        })

        op2.ready.tap( ( err, op ) =>
        {
          track.push( 'ready' );
          test.identical( op2.process, null );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.procedure._name, null );
          test.identical( op2.procedure._object, null );
          test.identical( op2.state, 'terminated' );
          test.identical( op2.exitReason, null );
          test.identical( op2.exitReason, null );
          test.identical( op2.exitCode, null );
          test.identical( op2.exitSignal, null );
          test.identical( op2.error, null );
          test.identical( op2.process, null );
          test.identical( op2.output, '' );
          test.identical( op2.ended, true );
          test.identical( op2.streamOut, null );
          test.identical( op2.streamErr, null );
          if( tops.mode === 'fork' )
          {
            test.identical( op2.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
            test.identical( op2.fullExecPath, programPath + ` id:${counter + 1}` );
          }
          else
          {
            test.identical( op2.stdio, [ 'pipe', 'pipe', 'pipe' ] );
            test.identical( op2.fullExecPath, `node ${programPath} id:${counter + 1}` );
          }
          test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate', 'ready' ] );
          track = [];
          return null;
        })
      });
      return null;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync :${tops.deasync}, dry : 1, without error, con* checks`;

      let options =
      {
        execPath : [ 'err ' + programPath + ' id:1', 'err ' + programPath + ' id:2' ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        outputCollecting : 1,
        dry : 1
      }

      let returned = _.process.startMultiple( options )

      test.identical( options.procedure._name, null );
      test.identical( options.state, 'terminated' );
      test.identical( options.exitReason, 'normal' );
      test.identical( options.exitCode, null );
      test.identical( options.exitSignal, null );
      test.identical( options.error, null );
      test.identical( options.pnd, undefined );
      test.identical( options.output, '' );
      test.identical( options.ended, true );
      if( tops.sync && !tops.deasync )
      {
        test.true( !_.streamIs( options.streamOut ) );
        test.true( !_.streamIs( options.streamErr ) );
      }
      else
      {
        test.true( _.streamIs( options.streamOut ) );
        test.true( _.streamIs( options.streamErr ) );
      }
      if( tops.mode === 'fork' )
      {
        test.identical( options.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
      }
      else
      {
        test.identical( options.stdio, [ 'pipe', 'pipe', 'pipe' ] );
      }

      options.sessions.forEach( ( op2, counter ) =>
      {
        op2.conStart.tap( ( err, op ) =>
        {
          track.push( 'conStart' );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.process, null );
          return null;
        })

        op2.conDisconnect.tap( ( err, op ) =>
        {
          track.push( 'conDisconnect' );
          test.identical( err, _.dont );
          test.identical( op, undefined );
          test.identical( op2.process, null );
          return null;
        })

        op2.conTerminate.tap( ( err, op ) =>
        {
          track.push( 'conTerminate' );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.process, null );
          return null;
        })

        op2.ready.tap( ( err, op ) =>
        {
          track.push( 'ready' );
          test.identical( op2.process, null );
          test.identical( err, undefined );
          test.identical( op, op2 );
          test.identical( op2.procedure._name, null );
          test.identical( op2.procedure._object, null );
          test.identical( op2.state, 'terminated' );
          test.identical( op2.exitReason, null );
          test.identical( op2.exitReason, null );
          test.identical( op2.exitCode, null );
          test.identical( op2.exitSignal, null );
          test.identical( op2.error, null );
          test.identical( op2.process, null );
          test.identical( op2.output, '' );
          test.identical( op2.ended, true );
          test.identical( op2.streamOut, null );
          test.identical( op2.streamErr, null );
          if( tops.mode === 'fork' )
          test.identical( op2.stdio, [ 'pipe', 'pipe', 'pipe', 'ipc' ] );
          else
          test.identical( op2.stdio, [ 'pipe', 'pipe', 'pipe' ] );
          test.identical( op2.fullExecPath, `err ${programPath} id:${counter + 1}` );
          test.identical( track, [ 'conStart', 'conDisconnect', 'conTerminate', 'ready' ] );
          track = [];
          return null;
        })
      });
      return null;
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    console.log( 'Not printed' );
  }
}

//

function startSingleOptionCurrentPath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testFilePath = a.path.join( a.routinePath, 'program1TestFile' );
  let locals = { testFilePath };
  let programPath = a.program({ routine : program1, locals });
  let modes = [ 'shell', 'spawn', 'fork' ]

  modes.forEach( ( mode ) =>
  {
    a.ready.tap( () => test.open( mode ) )
    a.ready.then( () => run( mode ) )
    a.ready.tap( () => test.close( mode ) )
  })

  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( function()
    {
      let o =
      {
        execPath :  mode !== 'fork' ? 'node ' + programPath : programPath,
        currentPath : __dirname,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
      }
      return _.process.startSingle( o )
      .then( function( op )
      {
        let got = a.fileProvider.fileRead( testFilePath );
        test.identical( got, __dirname );
        return null;
      })
    })

    /* */

    ready.then( function()
    {
      test.case = 'normalized, currentPath leads to root of current drive';

      let trace = a.path.traceToRoot( a.path.normalize( __dirname ) );
      let currentPath = trace[ 1 ];

      let o =
      {
        execPath :  mode !== 'fork' ? 'node ' + programPath : programPath,
        currentPath,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
      }

      return _.process.startSingle( o )
      .then( function( op )
      {
        let got = a.fileProvider.fileRead( testFilePath );
        test.identical( got, a.path.nativize( currentPath ) );
        return null;
      })
    })

    /* */

    ready.then( function()
    {
      test.case = 'normalized with slash, currentPath leads to root of current drive';

      let trace = a.path.traceToRoot( a.path.normalize( __dirname ) );
      let currentPath = trace[ 1 ] + '/';

      let o =
      {
        execPath :  mode !== 'fork' ? 'node ' + programPath : programPath,
        currentPath,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
      }

      return _.process.startSingle( o )
      .then( function( op )
      {
        let got = a.fileProvider.fileRead( testFilePath );
        if( process.platform === 'win32')
        test.identical( got, a.path.nativize( currentPath ) );
        else
        test.identical( got, trace[ 1 ] );
        return null;
      })
    })

    /* */

    ready.then( function()
    {
      test.case = 'nativized, currentPath leads to root of current drive';

      let trace = a.path.traceToRoot( __dirname );
      let currentPath = a.path.nativize( trace[ 1 ] )

      let o =
      {
        execPath :  mode !== 'fork' ? 'node ' + programPath : programPath,
        currentPath,
        mode,
        stdio : 'pipe',
        outputCollecting : 1,
      }

      return _.process.startSingle( o )
      .then( function( op )
      {
        let got = a.fileProvider.fileRead( testFilePath );
        test.identical( got, currentPath )
        return null;
      })
    })

    return ready;
  }



  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.fileProvider.fileWrite( testFilePath, process.cwd() );
  }

}

//

function startMultipleOptionCurrentPath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );
    let o2 =
    {
      execPath : mode === 'fork' ? programPath : 'node ' + programPath,
      currentPath : [ a.routinePath, __dirname ],
      stdio : 'pipe',
      outputCollecting : 1
    }

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath : single, currentPath : multiple`;

      let returned = _.process.startMultiple( _.mapSupplement( { mode : `${mode}` }, o2 ) );

      returned.then( ( op ) =>
      {
        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];

        test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
        test.identical( o1.exitCode, 0 );

        test.true( _.strHas( o2.output, __dirname ) );
        test.identical( o2.exitCode, 0 );

        return op;
      })

      return returned;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${mode}, execPath : multiple, currentPath : multiple`;
      let returned = _.process.startMultiple( _.mapSupplement( { mode : `${mode}`, execPath : [ mode === 'fork' ? programPath : 'node ' + programPath, mode === 'fork' ? programPath : 'node ' + programPath ] }, o2 ) );

      returned.then( ( op ) =>
      {
        let o1 = op.sessions[ 0 ];
        let o2 = op.sessions[ 1 ];
        let o3 = op.sessions[ 2 ];
        let o4 = op.sessions[ 3 ];

        test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
        test.identical( o1.exitCode, 0 );

        test.true( _.strHas( o2.output, __dirname ) );
        test.identical( o2.exitCode, 0 );

        test.true( _.strHas( o3.output, a.path.nativize( a.routinePath ) ) );
        test.identical( o3.exitCode, 0 );

        test.true( _.strHas( o4.output, __dirname ) );
        test.identical( o4.exitCode, 0 );

        return op;
      })

      return returned;
    })

    return ready;
  }

  /* ORIGINAL */
  // let o2 =
  // {
  //   execPath : 'node ' + programPath,
  //   ready : a.ready,
  //   currentPath : [ a.routinePath, __dirname ],
  //   stdio : 'pipe',
  //   outputCollecting : 1
  // }

  // /* */

  // _.process.start( _.mapSupplement( { mode : 'shell' }, o2 ) );

  // a.ready.then( ( op ) =>
  // {
  //   let o1 = op.sessions[ 0 ];
  //   let o2 = op.sessions[ 1 ];

  //   test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
  //   test.identical( o1.exitCode, 0 );

  //   test.true( _.strHas( o2.output, __dirname ) );
  //   test.identical( o2.exitCode, 0 );

  //   return op;
  // })

  // /* */

  // _.process.start( _.mapSupplement( { mode : 'spawn' }, o2 ) );

  // a.ready.then( ( op ) =>
  // {
  //   let o1 = op.sessions[ 0 ];
  //   let o2 = op.sessions[ 1 ];

  //   test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
  //   test.identical( o1.exitCode, 0 );

  //   test.true( _.strHas( o2.output, __dirname ) );
  //   test.identical( o2.exitCode, 0 );

  //   return op;
  // })

  // /* */

  // _.process.start( _.mapSupplement( { mode : 'fork', execPath : programPath }, o2 ) );

  // a.ready.then( ( op ) =>
  // {
  //   let o1 = op.sessions[ 0 ];
  //   let o2 = op.sessions[ 1 ];

  //   test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
  //   test.identical( o1.exitCode, 0 );

  //   test.true( _.strHas( o2.output, __dirname ) );
  //   test.identical( o2.exitCode, 0 );

  //   return op;
  // })

  // /*  */

  // _.process.start( _.mapSupplement( { mode : 'spawn', execPath : [ 'node ' + programPath, 'node ' + programPath ] }, o2 ) );

  // a.ready.then( ( op ) =>
  // {
  //   let o1 = op.sessions[ 0 ];
  //   let o2 = op.sessions[ 1 ];
  //   let o3 = op.sessions[ 2 ];
  //   let o4 = op.sessions[ 3 ];

  //   test.true( _.strHas( o1.output, a.path.nativize( a.routinePath ) ) );
  //   test.identical( o1.exitCode, 0 );

  //   test.true( _.strHas( o2.output, __dirname ) );
  //   test.identical( o2.exitCode, 0 );

  //   test.true( _.strHas( o3.output, a.path.nativize( a.routinePath ) ) );
  //   test.identical( o3.exitCode, 0 );

  //   test.true( _.strHas( o4.output, __dirname ) );
  //   test.identical( o4.exitCode, 0 );

  //   return op;
  // })

  /* - */

  function testApp()
  {
    console.log( process.cwd() );
  }
}

//

function startPassingThrough( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath1 = a.program( program1 );
  let testAppPath2 = a.program( program2 );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /*
   program1 spawns program2 with options read from op.js
   Options for program2 are provided to program1 through file op.js.
   This method is used instead of ipc messages because second method requires to call process.disconnect in program1,
   otherwise program1 will not exit after termination of program2.
   File op.js is written on each test case, before spawn of program1
   Also, this method is used to exclude output of program2 from tester in case when stdio:inherit is used
  */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.open( `mode : ${ mode }` );
      test.open( '0 args to parent process' );
      return null;
    } );

    /* */

    ready.then( () =>
    {
      test.case = 'args to child = `testAppPath2`';
      let o =
      {
        execPath : mode === 'fork' ? null : 'node ',
        args : [ testAppPath2 ],
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[]\n` );
        return null;
      })

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child : none';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child : a';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        args : 'a',
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ \'a\' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /*  */

    ready.then( () =>
    {
      test.case = 'args to child : a, b, c';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        args : [ 'a', 'b', 'c' ],
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ \'a\', \'b\', \'c\' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child in execPath: a, b, c';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 + ' a b c' : 'node ' + testAppPath2 + ' a b c',
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ \'a\', \'b\', \'c\' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child in execPath: a and in args : b, c';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 + ' a' : 'node ' + testAppPath2 + ' a',
        args : [ 'b', 'c' ],
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ \'a\', \'b\', \'c\' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.close( '0 args to parent process' );
      return null;
    } )

    /* - */

    ready.then( () =>
    {
      test.open( '1 arg to parent process' );
      return null;
    } );

    ready.then( () =>
    {
      test.case = 'args to child : none; args to parent : parentA';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        args : 'parentA',
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ 'parentA' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child : a; args to parent : parentA';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        args : 'a',
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        args : 'parentA',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ 'a', 'parentA' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /*  */

    ready.then( () =>
    {
      test.case = 'args to child : a, b, c; args to parent : parentA';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        args : [ 'a', 'b', 'c' ],
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1,
        mode : 'spawn',
        args : 'parentA',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ 'a', 'b', 'c', 'parentA' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child in execPath: a, b, c; args to parent in execPath : parentA';

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 + ' a b c' : 'node ' + testAppPath2 + ' a b c',
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1 + ' parentA',
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ 'a', 'b', 'c', 'parentA' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.case = 'args to child in execPath: a and in args : b, c; args to parent in execPath : parentA, and in args : empty array'

      let o =
      {
        execPath : mode === 'fork' ? testAppPath2 + ' a' : 'node ' + testAppPath2 + ' a',
        args : [ 'b', 'c' ],
        outputCollecting : 0,
        outputPiping : 0,
        mode,
        throwingExitCode : 0,
        applyingExitCode : 0,
        stdio : 'inherit'
      }
      a.fileProvider.fileWrite({ filePath : a.abs( 'op.json' ), data : o, encoding : 'json' });

      let o2 =
      {
        execPath : 'node ' + testAppPath1 + ' parentA',
        args : [],
        mode : 'spawn',
        stdio : 'pipe',
        outputPiping : 1,
        outputCollecting : 1,
      }
      _.process.startMinimal( o2 );

      o2.conTerminate.then( () =>
      {
        test.identical( o2.output, `[ 'a', 'b', 'c', 'parentA' ]\n` );
        return null;
      });

      return o2.conTerminate;
    })

    /* */

    ready.then( () =>
    {
      test.close( '1 arg to parent process' );
      return null;
    } )

    /* - */

    ready.then( () =>
    {
      test.close( `mode : ${ mode }` );
      return null;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    let o = _.fileProvider.fileRead({ filePath : _.path.join( __dirname, 'op.json' ), encoding : 'json' });
    o.currentPath = __dirname;
    _.process.startPassingThrough( o );
  }

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    console.log( process.argv.slice( 2 ) );
  }
}

startPassingThrough.timeOut = 5e5;
startPassingThrough.rapidity = -1;

//

function startMinimalOptionUid( test ) /* Runs only through `sudo` ( i.e. with superuser/root provileges ) */
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }`;

      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        outputCollecting : 1,
        mode,
        uid : 11
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, '11\n' );

        return null;
      } )


    } )

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    console.log( process.getuid() );
  }
}

startMinimalOptionUid.experimental = true;

//

function startMinimalOptionGid( test ) /* Runs only through `sudo` ( i.e. with superuser/root provileges ) */
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );

  return a.ready;

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${ mode }`;

      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        outputCollecting : 1,
        mode,
        gid : 15
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.output, '15\n' );

        return null;
      } )

    } )

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wProcess' );

    console.log( process.getgid() );
  }
}

startMinimalOptionGid.experimental = true;

//

function startSingleOptionProcedure( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );

  return a.ready;

  function run( tops )
  {
    let ready = new _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startSingle
      ({
        execPath : programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      })
    });

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : null`;

      let options =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        args : 'a',
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      let returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( op === options );
        test.equivalent( op.output, `[ 'a' ]` );
        test.true( _.strHas( op.procedure._name, 'PID:') );
        test.true( _.objectIs( op.procedure._object ) );

        return null;
      })

      return options.ready;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : false`;

      let options =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : false,
        outputCollecting : 1,
      }

      let returned =  _.process.startSingle( options )

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( op === options );
        test.equivalent( op.output, `[ 'a' ]` );
        test.identical( op.procedure, false );

        return null;
      })

      return options.ready;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : true`;

      let options =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        procedure : true,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      let returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( op === options );
        test.equivalent( op.output, `[ 'a' ]` );
        test.true( _.strHas( op.procedure._name, 'PID:') );
        test.true( _.objectIs( op.procedure._object ) );

        return null;
      })

      return options.ready;

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : _.Procedure()`;

      let options =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : _.Procedure(),
        outputCollecting : 1,
      }

      let returned =  _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( op === options );
        test.equivalent( op.output, `[ 'a' ]` );
        test.true( _.strHas( op.procedure._name, 'PID:') );
        test.true( _.objectIs( op.procedure._object ) );

        return null;
      })

      return options.ready;

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : _.Procedure({ _name : 'name', _object : 'object', _stack : 'stack' })`;

      let options =
      {
        execPath : tops.mode === 'fork' ? programPath : 'node ' + programPath,
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : _.Procedure({ _name : 'name', _object : 'object', _stack : 'stack' }),
        outputCollecting : 1,
      }

      let returned = _.process.startSingle( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( op === options );
        test.equivalent( op.output, `[ 'a' ]` );
        test.true( _.strHas( op.procedure._name, 'PID:') );
        test.true( _.objectIs( op.procedure._object ) );
        test.identical( op.procedure._stack, 'stack' );

        return null;
      })

      return options.ready;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

startSingleOptionProcedure.timeOut = 9e4; /* Locally : 8.406s */

//

function startMultipleOptionProcedure( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );

  return a.ready;

  function run( tops )
  {
    let ready = new _.Consequence().take( null );

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return test.shouldThrowErrorSync( () =>
    {
      _.process.startMultiple
      ({
        execPath : [ programPath, programPath ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync
      })
    });

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : null`;

      let options =
      {
        execPath : tops.mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ],
        args : 'a',
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      let returned =  _.process.startMultiple( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op, options );
        test.equivalent( op.output, `[ 'a' ]\n[ 'a' ]` );
        test.identical( op.procedure._name, null );
        test.true( _.objectIs( op.procedure._object ) );
        test.identical( op.procedure._object.execPath, [ `${tops.mode === 'fork' ? programPath : 'node ' + programPath}`, `${tops.mode === 'fork' ? programPath : 'node ' + programPath}` ] );

        op.sessions.forEach( ( run ) =>
        {
          test.identical( run.exitCode, 0 );
          test.identical( run.ended, true );
          test.equivalent( run.output, `[ 'a' ]` );
          test.true( _.strHas( run.procedure._name, 'PID:') );
          test.true( _.objectIs( run.procedure._object ) );
          test.identical( run.procedure._object.exitCode, 0 );
        } )

        return null;
      } )

      return options.ready;

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : false`;

      let options =
      {
        execPath : tops.mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : false,
        outputCollecting : 1,
      }

      let returned = _.process.startMultiple( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op, options );
        test.equivalent( op.output, `[ 'a' ]\n[ 'a' ]` );
        test.identical( op.procedure, false );
        op.sessions.forEach( ( run ) =>
        {
          test.identical( run.exitCode, 0 );
          test.identical( run.ended, true );
          test.equivalent( run.output, `[ 'a' ]` );
          test.identical( run.procedure, false );
        } )

        return null;
      } )

      return options.ready;

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : true`;

      let options =
      {
        execPath : tops.mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        procedure : true,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      let returned =  _.process.startMultiple( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op, options );
        test.equivalent( op.output, `[ 'a' ]\n[ 'a' ]` );
        test.identical( op.procedure._name, null );
        test.true( _.objectIs( op.procedure._object ) );
        test.identical( op.procedure._object.execPath, [ `${tops.mode === 'fork' ? programPath : 'node ' + programPath}`, `${tops.mode === 'fork' ? programPath : 'node ' + programPath}` ] );

        op.sessions.forEach( ( run ) =>
        {
          test.identical( run.exitCode, 0 );
          test.identical( run.ended, true );
          test.equivalent( run.output, `[ 'a' ]` );
          test.true( _.strHas( run.procedure._name, 'PID:') );
          test.true( _.objectIs( run.procedure._object ) );
          test.identical( run.procedure._object.exitCode, 0 );
        } )

        return null;
      } )

      return options.ready;
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync} procedure : _.Procedure()`;

      let options =
      {
        execPath : tops.mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : _.Procedure(),
        outputCollecting : 1,
      }

      let returned =  _.process.startMultiple( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op, options );
        test.equivalent( op.output, `[ 'a' ]\n[ 'a' ]` );
        test.identical( op.procedure._name, null );
        test.identical( op.procedure._object, null );

        op.sessions.forEach( ( run ) =>
        {
          test.identical( run.exitCode, 0 );
          test.identical( run.ended, true );
          test.equivalent( run.output, `[ 'a' ]` );
          test.true( _.strHas( run.procedure._name, 'PID:') );
          test.true( _.objectIs( run.procedure._object ) );
          test.identical( run.procedure._object.exitCode, 0 );
        } )

        return null;
      } )

      return options.ready;

    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${tops.mode}, sync : ${tops.sync}, deasync : ${tops.deasync}, procedure : _.Procedure({ _name : 'name', _object : 'object', _stack : 'stack' })`;

      let options =
      {
        execPath : tops.mode === 'fork' ? [ programPath, programPath ] : [ 'node ' + programPath, 'node ' + programPath ],
        mode : tops.mode,
        sync : tops.sync,
        deasync : tops.deasync,
        args : 'a',
        throwingExitCode : 0,
        procedure : _.Procedure({ _name : 'name', _object : 'object', _stack : 'stack' }),
        outputCollecting : 1,
      }

      let returned =  _.process.startMultiple( options );

      if( tops.sync )
      {
        test.true( !_.consequenceIs( returned ) );
      }
      else
      {
        test.true( _.consequenceIs( returned ) );
        if( tops.deasync )
        test.identical( returned.resourcesCount(), 1 );
        else
        test.identical( returned.resourcesCount(), 0 );
      }

      options.ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op, options );
        test.equivalent( op.output, `[ 'a' ]\n[ 'a' ]` );
        test.identical( op.procedure._name, 'name' );
        test.identical( op.procedure._object, 'object' );
        test.identical( op.procedure._stack, 'stack' );

        op.sessions.forEach( ( run ) =>
        {
          test.identical( run.exitCode, 0 );
          test.identical( run.ended, true );
          test.equivalent( run.output, `[ 'a' ]` );
          test.true( _.strHas( run.procedure._name, 'PID:') );
          test.true( _.objectIs( run.procedure._object ) );
          test.identical( run.procedure._object.exitCode, 0 );
          test.notIdentical( run.procedure._stack, 'stack' );
        } )

        return null;
      } )

      return options.ready;
    })

    return ready;
  }

  /* - */

  function program1()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

startMultipleOptionProcedure.timeOut = 18e4; /* 17.983s */

// --
// pid
// --

function startMinimalDiffPid( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testFilePath = a.abs( a.routinePath, 'testFile' );
  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) =>
  {
    a.ready.then( () =>
    {
      a.fileProvider.filesDelete( a.routinePath );
      let locals =
      {
        mode,
      }
      a.program({ routine : testAppParent, locals });
      a.program( testAppChild );
      return null;
    })

    a.ready.tap( () => test.open( mode ) );
    a.ready.then( () => run( mode ) );
    a.ready.tap( () => test.close( mode ) );
  });

  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = new _.Consequence().take( null )

    /*  */

    ready.then( () =>
    {
      test.case = 'process termination begins after short delay, detached process should continue to work after parent death';

      a.fileProvider.filesDelete( testFilePath );
      a.fileProvider.dirMakeForFile( testFilePath );

      let o =
      {
        execPath : 'node testAppParent.js stdio : ignore outputPiping : 0 outputCollecting : 0',
        mode : 'spawn',
        outputCollecting : 1,
        currentPath : a.routinePath,
        ipc : 1,
      }
      let con = _.process.startMinimal( o );
      let data;

      o.pnd.on( 'message', ( e ) =>
      {
        data = e;
        data.childPid = _.numberFrom( data.childPid );
      })

      con.then( ( op ) =>
      {
        test.will = 'parent is dead, child is still alive';
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.true( !_.process.isAlive( op.pnd.pid ) );
        test.true( _.process.isAlive( data.childPid ) );
        return _.time.out( context.t2 * 2 );
      })

      con.then( () =>
      {
        test.will = 'both dead';

        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.true( !_.process.isAlive( data.childPid ) );

        test.true( a.fileProvider.fileExists( testFilePath ) );
        let childPid = a.fileProvider.fileRead( testFilePath );
        childPid = _.numberFrom( childPid );
        console.log(  childPid );
        /* if shell then could be 2 processes, first - terminal, second application */
        if( mode !== 'shell' )
        test.identical( data.childPid, childPid );
        console.log( `${mode} : PID is ${ data.childPid === childPid ? 'same' : 'different' }` );

        return null;
      })

      return con;
    })

    /*  */

    return ready;
  }

  /*  */

  function testAppParent()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let args = _.process.input();

    let o =
    {
      execPath : mode === 'fork' ? 'testAppChild.js' : 'node testAppChild.js',
      mode,
      detaching : true,
    }

    _.mapExtend( o, args.map );
    if( o.ipc !== undefined )
    o.ipc = _.boolFrom( o.ipc );

    _.process.startMinimal( o );

    console.log( o.pnd.pid )

    process.send({ childPid : o.pnd.pid });

    o.conStart.thenGive( () =>
    {
      _.procedure.terminationBegin();
    })
  }

  function testAppChild()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    console.log( 'Child process start', process.pid );
    _.time.out( context.t1 * 2, () => /* 2000 */
    {
      let filePath = _.path.join( __dirname, 'testFile' );
      _.fileProvider.fileWrite( filePath, _.toStr( process.pid ) );
      console.log( 'Child process end' )
      return null;
    })
  }
}

startMinimalDiffPid.timeOut = 180000;

//

function pidFrom( test )
{
  let o =
  {
    execPath : 'node -v',
  }
  let ready = _.process.startMinimal( o );
  let expected = o.pnd.pid;

  test.identical( _.process.pidFrom( o ), expected )
  test.identical( _.process.pidFrom( o.pnd ), expected )
  test.identical( _.process.pidFrom( o.pnd.pid ), expected )

  if( !Config.debug )
  return ready;

  test.shouldThrowErrorSync( () => _.process.pidFrom() );
  test.shouldThrowErrorSync( () => _.process.pidFrom( [] ) );
  test.shouldThrowErrorSync( () => _.process.pidFrom( {} ) );
  test.shouldThrowErrorSync( () => _.process.pidFrom( { pnd : {} } ) );
  test.shouldThrowErrorSync( () => _.process.pidFrom( '123' ) );

  return ready;
}

//

function isAlive( test )
{
  let track = [];
  let o =
  {
    execPath : `node -e "setTimeout( () => { console.log( 'child terminate' ) }, 3000 )"`,
  }
  _.process.startMinimal( o );

  o.conStart.then( () =>
  {
    track.push( 'conStart' );
    test.identical( _.process.isAlive( o ), true );
    test.identical( _.process.isAlive( o.pnd ), true );
    test.identical( _.process.isAlive( o.pnd.pid ), true );
    return null;
  })

  o.conTerminate.then( () =>
  {
    track.push( 'conTerminate' );
    test.identical( _.process.isAlive( o ), false );
    test.identical( _.process.isAlive( o.pnd ), false );
    test.identical( _.process.isAlive( o.pnd.pid ), false );
    test.identical( track, [ 'conStart', 'conTerminate' ] )
    return null;
  })

  let ready = _.Consequence.AndKeep( o.conStart, o.conTerminate );

  if( !Config.debug )
  return ready;

  ready.then( () =>
  {
    test.shouldThrowErrorSync( () => _.process.isAlive() );
    test.shouldThrowErrorSync( () => _.process.isAlive( [] ) );
    test.shouldThrowErrorSync( () => _.process.isAlive( {} ) );
    test.shouldThrowErrorSync( () => _.process.isAlive( { pnd : {} } ) );
    test.shouldThrowErrorSync( () => _.process.isAlive( '123' ) );

    return null;
  })

  return ready;
}

//

function statusOf( test )
{
  let o =
  {
    execPath : `node -e "setTimeout( () => { console.log( 'child terminate' ) }, 3000 )"`,
  }
  let track = [];
  _.process.startMinimal( o );

  o.conStart.then( () =>
  {
    track.push( 'conStart' )
    test.identical( _.process.statusOf( o ), 'alive' );
    test.identical( _.process.statusOf( o.pnd ), 'alive' );
    test.identical( _.process.statusOf( o.pnd.pid ), 'alive' );
    return null;
  })

  o.conTerminate.then( () =>
  {
    track.push( 'conTerminate' );
    test.identical( _.process.statusOf( o ), 'dead' );
    test.identical( _.process.statusOf( o.pnd ), 'dead' );
    test.identical( _.process.statusOf( o.pnd.pid ), 'dead' );
    test.identical( track, [ 'conStart', 'conTerminate' ] );
    return null;
  })

  let ready = _.Consequence.AndKeep( o.conStart, o.conTerminate );

  if( !Config.debug )
  return ready;

  ready.then( () =>
  {
    test.shouldThrowErrorSync( () => _.process.statusOf() );
    test.shouldThrowErrorSync( () => _.process.statusOf( [] ) );
    test.shouldThrowErrorSync( () => _.process.statusOf( {} ) );
    test.shouldThrowErrorSync( () => _.process.statusOf( { pnd : {} } ) );
    test.shouldThrowErrorSync( () => _.process.statusOf( '123' ) );

    return null;
  })

  return ready;
}

//

function exitReason( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, initial value`;

      let testAppPath = a.program({ routine : testApp, locals : { reasons : null, reset : 0 } });

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        outputCollecting : 1,
        mode,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, 'null' );
        a.fileProvider.fileDelete( testAppPath )
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, reason : 'reason'`;

      let testAppPath = a.program({ routine : testApp, locals : { reasons : [ 'reason' ], reset : 0 } });

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        outputCollecting : 1,
        mode,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, `[ null, 'reason' ]` );
        a.fileProvider.fileDelete( testAppPath )
        return null;
      } )
    })

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, initial, set, update reason`;

      let testAppPath = a.program({ routine : testApp, locals : { reasons : [ 'reason1', 'reason2' ], reset : 0 } });

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        outputCollecting : 1,
        mode,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, `[ null, 'reason1', 'reason2' ]` );
        a.fileProvider.fileDelete( testAppPath );
        return null;
      } )
    })

    ready.then( () =>
    {
      test.case = `mode : ${ mode }, initial, set, update, reset reason`;

      let testAppPath = a.program({ routine : testApp, locals : { reasons : [ 'reason1', 'reason2' ], reset : 1 } });

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        outputCollecting : 1,
        mode,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.equivalent( op.output, `[ null, 'reason1', 'reason2', null ]` );
        a.fileProvider.fileDelete( testAppPath );
        return null;
      } )
    })

    return ready;
  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    let result = [];

    if( !reasons )
    {
      console.log( _.process.exitReason() );
      return;
    }

    result.push( _.process.exitReason() );

    reasons.forEach( ( reason ) =>
    {
      _.process.exitReason( reason );
      result.push( _.process.exitReason() );
    })

    if( reset )
    {
      _.process.exitReason( null );
      result.push( _.process.exitReason() );
    }

    console.log( result );

  }
}

//

function exitCode( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.open( `mode : ${ mode }` );
      return null
    })

    ready.then( () =>
    {
      test.case = 'initial value';
      let locals =
      {
        code : null
      }
      let programPath = a.program({ routine : testAppExitCode, locals });
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'set code';
      let locals =
      {
        code : 1
      }
      let programPath = a.program({ routine : testAppExitCode, locals});
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'update reason';
      let locals =
      {
        code : 2
      }
      let programPath = a.program({ routine : testAppExitCode, locals});
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 2 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'wrong execPath'

      if( mode === 'spawn' )
      return test.shouldThrowErrorAsync( _.process.startMinimal({ execPath : '1', throwingExitCode : 0, mode }) );

      return _.process.startMinimal({ execPath : '1', throwingExitCode : 0, mode })
      .then( ( op ) =>
      {
        test.ni( op.exitCode, 0 )
        test.identical( op.ended, true );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'throw error in app';
      let programPath = a.program( testAppError );
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 1 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'error in subprocess';
      let programPath = a.program({ routine : testApp, locals : { options : null } })
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        if( process.platform === 'win32' )
        test.notIdentical( op.exitCode, 0 )/* returns 4294967295 which is -1 to uint32 */
        else
        test.identical( op.exitCode, 255 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'no error in subprocess';
      let locals =
      {
        options : { execPath : 'echo' }
      }
      let programPath = a.program({ routine : testApp, locals });
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.il( op.exitCode, 0 );
        test.il( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.case = 'explicitly exit with code : 100';
      let locals =
      {
        code : 100
      }
      let programPath = a.program({ routine : testAppExit, locals});
      let options =
      {
        execPath : mode === 'fork' ? programPath : 'node ' + programPath,
        throwingExitCode : 0,
        mode
      }
      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 100 );
        test.identical( op.ended, true );

        a.fileProvider.fileDelete( programPath );
        return null;
      } )
    })

    /* */

    ready.then( () =>
    {
      test.close( `mode : ${ mode }` );
      return null;
    } )

    return ready;
  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    return _.process.startMinimal( options );
  }

  function testAppError()
  {
    throw new Error();
  }

  function testAppExit()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    return _.process.exit( code );
  }

  function testAppExitCode()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    if( code )
    return _.process.exitCode( code );

    return _.process.exitCode();
  }

}

// --
// termination
// --

function startMinimalOptionVerbosityLogging( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `logging without error; mode : ${mode}; verbosity : 4`;
      let testAppPath2 = a.program( testApp2 );
      let locals = { programPath : testAppPath2, verbosity : 4 };
      let testAppPath = a.program( { routine : testApp, locals } );

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.identical( op.state, 'terminated' );
        test.identical( _.strCount( op.output, '< Process returned error code 0' ), 0 );
        test.identical( _.strCount( op.output, `Launched as "node ${ testAppPath2 }"` ), 0 );
        test.identical( _.strCount( op.output, `Launched at ${ _.strQuote( op.currentPath ) }` ), 0 );
        test.identical( _.strCount( op.output, '-> Stderr' ), 0 );
        test.identical( _.strCount( op.output, '-< Stderr' ), 0 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      } )

    })

    /* */

    ready.then( () =>
    {
      test.case = `logging with error; mode : ${mode}; verbosity : 4`;
      let testAppPathError = a.program( testAppError );
      let locals = { programPath : testAppPathError, verbosity : 4 };
      let testAppPath = a.program( { routine : testApp, locals } );

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.identical( op.state, 'terminated' );
        test.identical( _.strCount( op.output, '< Process returned error code 255' ), 0 );
        test.identical( _.strCount( op.output, `Launched as "node ${ testAppPathError }"` ), 0 );
        test.identical( _.strCount( op.output, `Launched at ${ _.strQuote( op.currentPath ) }` ), 0 );
        test.identical( _.strCount( op.output, '-> Stderr' ), 0 );
        test.true( !_.strHas( op.output, '= Message of error' ) );
        test.true( !_.strHas( op.output, '= Beautified calls stack' ) );
        test.true( !_.strHas( op.output, '= Throws stack' ) );
        test.true( !_.strHas( op.output, '= Process' ) );
        test.true( !_.strHas( op.output, 'Source code from' ) );
        test.identical( _.strCount( op.output, '-< Stderr' ), 0 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPathError );

        return null;
      } )

    })

    /* */

    ready.then( () =>
    {
      test.case = `logging without error; mode : ${mode}; verbosity : 5`;
      let testAppPath2 = a.program( testApp2 );
      let locals = { programPath : testAppPath2, verbosity : 5 };
      let testAppPath = a.program( { routine : testApp, locals } );

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.identical( op.state, 'terminated' );
        test.identical( _.strCount( op.output, '< Process returned error code 0' ), 1 );
        test.identical( _.strCount( op.output, `Launched as "node ${ testAppPath2 }"` ), 0 );
        test.identical( _.strCount( op.output, `Launched at ${ _.strQuote( op.currentPath ) }` ), 0 );
        test.identical( _.strCount( op.output, '-> Stderr' ), 0 );
        test.identical( _.strCount( op.output, '-< Stderr' ), 0 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPath2 );

        return null;
      } )

    })

    /* */

    ready.then( () =>
    {
      test.case = `logging with error; mode : ${mode}; verbosity : 5`;
      let testAppPathError = a.program( testAppError );
      let locals = { programPath : testAppPathError, verbosity : 5 };
      let testAppPath = a.program( { routine : testApp, locals } );

      let options =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputCollecting : 1,
      }

      return _.process.startMinimal( options )
      .then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.identical( op.state, 'terminated' );
        /* Windows returns 4294967295 which is -1 to uint32 */
        if( process.platform === 'win32' )
        test.identical( _.strCount( op.output, '< Process returned error code 4294967295' ), 1 );
        else
        test.identical( _.strCount( op.output, '< Process returned error code 255' ), 1 );
        test.identical( _.strCount( op.output, `Launched as "node ${ testAppPathError }"` ), 1 );
        test.identical( _.strCount( op.output, `Launched at ${ _.strQuote( op.currentPath ) }` ), 1 );
        test.identical( _.strCount( op.output, '-> Stderr' ), 1 );
        test.true( _.strHas( op.output, '= Message of error' ) );
        test.true( _.strHas( op.output, '= Beautified calls stack' ) );
        test.true( _.strHas( op.output, '= Throws stack' ) );
        test.true( _.strHas( op.output, '= Process' ) );
        test.true( _.strHas( op.output, 'Source code from' ) );
        test.identical( _.strCount( op.output, '-< Stderr' ), 1 );

        a.fileProvider.fileDelete( testAppPath );
        a.fileProvider.fileDelete( testAppPathError );

        return null;
      } )

    })

    return ready;
  }

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    let options =
    {
      execPath : 'node ' + programPath,
      throwingExitCode : 0,
      outputCollecting : 0,
      outputPiping : 0,
      verbosity
    }

    return _.process.startMinimal( options );
  }

  function testApp2()
  {
    console.log();
  }

  function testAppError()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    return _.process.startMinimal();
  }

}

startMinimalOptionVerbosityLogging.timeOut = 3e5;

//

function startMultipleOutput( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let track = [];

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 0, deasync : 1, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 0, mode }) ) );
  modes.forEach( ( mode ) => a.ready.then( () => run({ sync : 1, deasync : 1, mode }) ) );
  return a.ready;

  /* - */

  function run( tops )
  {
    let ready = new _.Consequence().take( null )

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return null;

    /* */

    ready.then( () =>
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} concurrent:0 mode:${tops.mode}`;
      track = [];
      let t1 = _.time.now();
      let ready2 = new _.Consequence().take( null ).delay( context.t1 / 10 );
      let o =
      {
        execPath : [ ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:1`, ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputPiping : 1,
        outputCollecting : 1,
        outputAdditive : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        concurrent : 0,
        mode : tops.mode,
        ready : ready2,
      }

      let returned = _.process.startMultiple( o );

      o.conStart.tap( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.true( op === o );
        processPipe( o, 0 );
      });

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.true( op === o );
      });

      o.ready.then( ( op ) =>
      {
        track.push( 'ready' );

        if( tops.sync || tops.deasync )
        {
          var exp =
          [
            'conStart',
            'conTerminate',
            'ready',
          ]
          test.identical( track, exp );
        }
        else
        {
          /*
          on older version of nodejs event finish goes before event end
          */
          // var exp =
          // [
          //   'conStart',
          //   '0.out:1::begin',
          //   '0.out:1::end',
          //   '0.err:1::err',
          //   '0.out:2::begin',
          //   '0.out:2::end',
          //   '0.err:2::err',
          //   '0.err.finish',
          //   '0.err.end',
          //   '0.out.finish',
          //   '0.out.end',
          //   'conTerminate',
          //   'ready',
          // ]

          // test.identical( new Set( ... track ), new Set( ... exp ) );

          // test.lt( track.indexOf( '0.out:1::end' ), track.indexOf( '0.out:2::begin' ) );
          // test.lt( track.indexOf( '0.out:1::begin' ), track.indexOf( '0.out:1::end' ) );
          // test.lt( track.indexOf( '0.out:1::end' ), track.indexOf( '0.err:1::err' ) );
          // test.lt( track.indexOf( '0.out:2::begin' ), track.indexOf( '0.out:2::end' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.err:2::err' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.err.finish' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.err.end' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.out.finish' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.out.end' ) );
          // test.lt( track.indexOf( '0.err.finish' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.err.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.out.finish' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.out.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( 'conTerminate' ), track.indexOf( 'ready' ) );

          /* qqq for Yevhen : replace with several calls of _.dissector.dissect() | aaa : Done. */
          test.true( _.dissector.dissect( '**<conStart>' + '**<0.out:1::begin>**<0.out:1::end>' + '**<0.err:1::err>' + '**<0.err.end>**<0.err.finish>' + '**<0.out.end>**<0.out.finish>' + '**<conTerminate>' + '**<ready>**', track.toString() ).matched );
          test.true( _.dissector.dissect( '**<conStart>' + '**<0.out:2::begin>**<0.out:2::end>' + '**<0.err:2::err>' + '**<0.err.end>**<0.err.finish>' + '**<0.out.end>**<0.out.finish>' + '**<conTerminate>' + '**<ready>**', track.toString() ).matched );

        }

        var exp =
`
1::begin
1::end
1::err
2::begin
2::end
2::err
`
        test.equivalent( op.output, exp );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.true( op === o );

        if( !tops.sync && !tops.deasync )
        test.true( _.longHas( track, '0.out.end' ) );
        test.true( !_.longHas( track, '1.out.end' ) );
        test.true( !_.longHas( track, '2.out.end' ) );

        if( !tops.sync || tops.deasync )
        {
          test.identical( op.streamOut._writableState.ended, true );
          test.identical( op.streamOut._readableState.ended, true );
          test.identical( op.streamErr._writableState.ended, true );
          test.identical( op.streamErr._readableState.ended, true );
        }
        else
        {
          test.true( op.streamOut === null );
          test.true( op.streamErr === null );
        }

        op.sessions.forEach( ( op2, counter ) =>
        {
          test.identical( op2.exitCode, 0 );
          test.identical( op2.exitSignal, null );
          test.identical( op2.exitReason, 'normal' );
          test.identical( op2.ended, true );
          let parsed = a.fileProvider.fileRead({ filePath : a.abs( `${counter+1}.json` ), encoding : 'json' });
          test.identical( parsed.id, counter+1 );

          if( !tops.sync || tops.deasync )
          {
            test.identical( op2.streamOut._writableState.ended, false );
            test.identical( op2.streamOut._readableState.ended, true );
            test.identical( op2.streamErr._writableState.ended, false );
            test.identical( op2.streamErr._readableState.ended, true );
          }
          else
          {
            test.true( op2.streamOut === null );
            test.true( op2.streamErr === null );
          }

        });
        return null;
      })

      return o.ready;
    })

    /* */

    ready.then( () =>
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} concurrent:1 mode:${tops.mode}`;
      if( tops.sync && !tops.deasync )
      return null;
      track = [];
      let t1 = _.time.now();
      let ready2 = new _.Consequence().take( null ).delay( context.t1 / 10 );
      let o =
      {
        execPath : [ ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:1`, ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputPiping : 1,
        outputCollecting : 1,
        outputAdditive : 1,
        sync : tops.sync,
        deasync : tops.deasync,
        concurrent : 1,
        mode : tops.mode,
        ready : ready2,
      }

      let returned = _.process.startMultiple( o );

      o.conStart.tap( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.true( op === o );
        processPipe( o, 0 );
        processPipe( o.sessions[ 0 ], 1 );
        processPipe( o.sessions[ 1 ], 2 );
      });

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.true( op === o );
      });

      o.ready.then( ( op ) =>
      {
        track.push( 'ready' );

        if( tops.sync || tops.deasync )
        {
          var exp =
          [
            'conStart',
            'conTerminate',
            'ready',
          ]
          test.identical( track, exp );
        }
        else
        {

          /*
          on older version of nodejs event finish goes before event end
          */
/*
          var exp =
          [
            'conStart',
            '0.out:1::begin',
            '1.out:1::begin',
            '0.out:2::begin',
            '2.out:2::begin',
            '0.out:1::end',
            '1.out:1::end',
            '0.out:2::end',
            '2.out:2::end',
            '0.err:1::err',
            '1.err:1::err',
            '1.err.end',
            '1.out.end',
            '0.err:2::err',
            '2.err:2::err',
            '0.err.finish',
            '2.err.end',
            '0.err.end',
            '0.out.finish',
            '2.out.end',
            '0.out.end',
            'conTerminate',
            'ready'
          ]
          let exp2 =
          [
            'conStart',
            '0.out:1::begin',
            '1.out:1::begin',
            '0.out:2::begin',
            '2.out:2::begin',
            '0.out:1::end',
            '1.out:1::end',
            '0.out:2::end',
            '2.out:2::end',
            '0.err:1::err',
            '1.err:1::err',
            '1.err.end',
            '1.out.end',
            '0.err:2::err',
            '2.err:2::err',
            '2.err.end',
            '0.err.end',
            '0.err.finish',
            '2.out.end',
            '0.out.end',
            '0.out.finish',
            'conTerminate',
            'ready'
          ]
*/
          // var exp =
          // [
          //   'conStart',
          //   '0.out:1::begin',
          //   '1.out:1::begin', 
          //   '0.out:2::begin',
          //   '2.out:2::begin',
          //   '0.out:1::end',
          //   '1.out:1::end',
          //   '0.out:2::end',
          //   '2.out:2::end',
          //   '0.err:1::err',
          //   '1.err:1::err',
          //   '1.out.end',
          //   '1.err.end',
          //   '0.err:2::err',
          //   '2.err:2::err',
          //   '2.out.end',
          //   '0.out.end',
          //   '0.out.finish',
          //   '2.err.end',
          //   '0.err.end',
          //   '0.err.finish',
          //   'conTerminate',
          //   'ready'
          // ]

          // test.identical( new Set( ... track ), new Set( ... exp ) );

          // test.lt( track.indexOf( '0.out:1::begin' ), track.indexOf( '0.out:1::end' ) ); //
          // test.lt( track.indexOf( '1.out:1::begin' ), track.indexOf( '0.out:1::end' ) );
          // test.lt( track.indexOf( '0.out:2::begin' ), track.indexOf( '0.out:1::end' ) );
          // test.lt( track.indexOf( '2.out:2::begin' ), track.indexOf( '0.out:1::end' ) );
          // test.lt( track.indexOf( '0.out:1::end' ), track.indexOf( '0.err:1::err' ) );
          // test.lt( track.indexOf( '1.out:1::end' ), track.indexOf( '0.err:1::err' ) );
          // test.lt( track.indexOf( '0.out:2::end' ), track.indexOf( '0.err:1::err' ) );
          // test.lt( track.indexOf( '2.out:2::end' ), track.indexOf( '0.err:1::err' ) );
          // test.lt( track.indexOf( '0.err:1::err' ), track.indexOf( '1.out.end' ) );
          // test.lt( track.indexOf( '1.err:1::err' ), track.indexOf( '1.out.end' ) );
          // test.lt( track.indexOf( '1.out.end' ), track.indexOf( '0.err:2::err' ) );
          // test.lt( track.indexOf( '1.err.end' ), track.indexOf( '0.err:2::err' ) );
          // test.lt( track.indexOf( '1.out.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '1.err.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.err:2::err' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '2.err:2::err' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '2.out.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.out.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.out.finish' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '2.err.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.err.end' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( '0.err.finish' ), track.indexOf( 'conTerminate' ) );
          // test.lt( track.indexOf( 'conTerminate' ), track.indexOf( 'ready' ) );

          /* qqq for Yevhen : replace with several calls of _.dissector.dissect() | aaa : Done. */
          test.true( _.dissector.dissect( '**<conStart>' + '**<0.out:1::begin>**<0.out:1::end>' + '**<0.err:1::err>**<0.err:2::err>**' + '<0.err.end>**<0.err.finish>' + '**<0.out.end>**<0.out.finish>**' + '<conTerminate>**' + '<ready>**', track.toString() ).matched );
          test.true( _.dissector.dissect( '**<conStart>' + '**<1.out:1::begin>**<1.out:1::end>' + '**<1.err:1::err>**<1.err.end>**' + '<1.out.end>**' + '<conTerminate>**' + '<ready>**', track.toString() ).matched );
          test.true( _.dissector.dissect( '**<conStart>' + '**<0.out:2::begin>**<0.out:2::end>' + '**<0.err.end>**<0.err.finish>**' + '<0.out.end>**<0.out.finish>**'  + '<conTerminate>**' + '<ready>**', track.toString() ).matched );
          test.true( _.dissector.dissect( '**<conStart>' + '**<2.out:2::begin>**<2.out:2::end>' + '**<2.err.end>**<2.out.end>**' + '<conTerminate>**' + '<ready>**', track.toString() ).matched );

        }

        /* aaa : fails on windows :
        - got :
          '1::begin
          1::end
          2::begin
          1::err
          2::end
          2::err'
        - expected :
          '1::begin
          2::begin
          1::end
          2::end
          1::err
          2::err'
        - difference :
          '1::begin
          *
        with accuracy 1e-7
        */

// qqq2 for Yevhen : example with dissector | aaa : Done.
//         var exp =
// `
// 1::begin
// 2::begin
// 1::end
// 2::end
// 1::err
// 2::err
// `
//         test.equivalent( op.output, exp );
        test.true( _.dissector.dissect( '**<1::begin>**<1::end>**<1::err>**', op.output ).matched );
        test.true( _.dissector.dissect( '**<2::begin>**<2::end>**<2::err>**', op.output ).matched );

        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.true( op === o );

        if( !tops.sync && !tops.deasync )
        {
          test.true( _.longHas( track, '0.out.end' ) );
          test.true( _.longHas( track, '1.out.end' ) );
          test.true( _.longHas( track, '2.out.end' ) );
        }

        if( !tops.sync || tops.deasync )
        {
          test.identical( op.streamOut._writableState.ended, true );
          test.identical( op.streamOut._readableState.ended, true );
          test.identical( op.streamErr._writableState.ended, true );
          test.identical( op.streamErr._readableState.ended, true );
        }
        else
        {
          test.true( op.streamOut === null );
          test.true( op.streamErr === null );
        }

        op.sessions.forEach( ( op2, counter ) =>
        {
          test.identical( op2.exitCode, 0 );
          test.identical( op2.exitSignal, null );
          test.identical( op2.exitReason, 'normal' );
          test.identical( op2.ended, true );
          let parsed = a.fileProvider.fileRead({ filePath : a.abs( `${counter+1}.json` ), encoding : 'json' });
          test.identical( parsed.id, counter+1 );

          if( !tops.sync || tops.deasync )
          {
            test.identical( op2.streamOut._writableState.ended, false );
            test.identical( op2.streamOut._readableState.ended, true );
            test.identical( op2.streamErr._writableState.ended, false );
            test.identical( op2.streamErr._readableState.ended, true );
          }
          else
          {
            test.true( op2.streamOut === null );
            test.true( op2.streamErr === null );
          }

        });

        return null;
      })

      return o.ready;
    })

    /* */

    return ready;
  }

  /* - */

  function processPipe( op, id )
  {
    streamPipe( op, op.streamOut, 'out', id );
    streamPipe( op, op.streamErr, 'err', id );
  }

  function streamPipe( op, steam, streamName, id )
  {
    if( op.sync && !op.deasync )
    return;
    steam.on( 'data', ( data ) =>
    {
      if( _.bufferAnyIs( data ) )
      data = _.bufferToStr( data );
      data = data.trim();
      console.log( `${id}.${streamName}`, data );
      track.push( `${id}.${streamName}:` + data );
    });
    steam.on( 'end', ( data ) =>
    {
      console.log( `${id}.${streamName}.end` );
      track.push( `${id}.${streamName}.end` );
    });
    steam.on( 'finish', ( data ) =>
    {
      console.log( `${id}.${streamName}.finish` );
      track.push( `${id}.${streamName}.finish` );
    });
  }

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    _.fileProvider.fileWrite({ filePath : _.path.join(__dirname, `${args.map.id}.json` ), data, encoding : 'json' });
    let sessionDelay = context.t1 * 0.5*args.map.id;
    setTimeout( () => console.log( `${args.map.id}::begin` ), sessionDelay );
    setTimeout( () => console.log( `${args.map.id}::end` ), context.t1+sessionDelay );
    setTimeout( () => console.error( `${args.map.id}::err` ), context.t1*2+sessionDelay );
  }

}

startMultipleOutput.rapidity = -1;
startMultipleOutput.timeOut = 5e5;
startMultipleOutput.description =
`
  - callback of event exit of each stream is called
  - streams of processes are joined
  - output is collected in op.output
`

//

function startMultipleOptionStdioIgnore( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let track = [];

  let modes = [ 'fork', 'spawn', 'shell' ];
  let outputAdditives = [ true, false ]

  outputAdditives.forEach( ( outputAdditive ) =>
  {
    a.ready.tap( () => test.open( `outputAdditive:${ outputAdditive }` ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ outputAdditive, sync : 0, deasync : 0, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ outputAdditive, sync : 0, deasync : 1, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ outputAdditive, sync : 1, deasync : 0, mode }) ) );
    modes.forEach( ( mode ) => a.ready.then( () => run({ outputAdditive, sync : 1, deasync : 1, mode }) ) );
    a.ready.tap( () => test.close( `outputAdditive:${ outputAdditive }` ) );
  });

  return a.ready;

  /* - */

  function run( tops )
  {
    let ready = new _.Consequence().take( null )

    if( tops.sync && !tops.deasync && tops.mode === 'fork' )
    return null;

    /* */

    ready.then( () =>
    {
      test.case = `sync:${tops.sync} deasync:${tops.deasync} mode:${tops.mode} concurrent:0 `;
      track = [];
      let t1 = _.time.now();
      let ready2 = new _.Consequence().take( null ).delay( context.t1 / 10 );
      let o =
      {
        execPath : [ ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:1`, ( tops.mode !== `fork` ?  `node ` : '' ) + `${programPath} id:2` ],
        currentPath : a.abs( '.' ),
        outputAdditive : tops.outputAdditive,
        stdio : 'ignore',
        sync : tops.sync,
        deasync : tops.deasync,
        concurrent : 0,
        mode : tops.mode,
        ready : ready2,
      }

      let returned = _.process.startMultiple( o );

      o.conStart.tap( ( err, op ) =>
      {
        track.push( 'conStart' );
        test.true( op === o );
      });

      o.conTerminate.tap( ( err, op ) =>
      {
        track.push( 'conTerminate' );
        test.true( op === o );
      });

      o.ready.then( ( op ) =>
      {
        track.push( 'ready' );

        var exp =
        [
          'conStart',
          'conTerminate',
          'ready',
        ]
        test.identical( track, exp );

        test.identical( op.output, null );
        test.identical( op.exitCode, 0 );
        test.identical( op.exitSignal, null );
        test.identical( op.exitReason, 'normal' );
        test.identical( op.ended, true );
        test.true( op === o );
        test.true( op.streamOut === null );
        test.true( op.streamErr === null );

        op.sessions.forEach( ( op2, counter ) =>
        {
          test.identical( op2.exitCode, 0 );
          test.identical( op2.exitSignal, null );
          test.identical( op2.exitReason, 'normal' );
          test.identical( op2.ended, true );
          test.identical( op2.output, null );
          let parsed = a.fileProvider.fileRead({ filePath : a.abs( `${counter+1}.json` ), encoding : 'json' });
          test.identical( parsed.id, counter+1 );
          test.true( op2.streamOut === null );
          test.true( op2.streamErr === null );
          test.true( op2.process.stdout === null );
          test.true( op2.process.stderr === null );
        });
        return null;
      })

      return o.ready;
    })

    /* */

    return ready;
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    let args = _.process.input();
    let data = { time : _.time.now(), id : args.map.id };
    _.fileProvider.fileWrite({ filePath : _.path.join(__dirname, `${args.map.id}.json` ), data, encoding : 'json' });
    let sessionDelay = context.t1 * 0.5*args.map.id;
    setTimeout( () => console.log( `${args.map.id}::begin` ), sessionDelay );
    setTimeout( () => console.log( `${args.map.id}::end` ), context.t1+sessionDelay );
    setTimeout( () => console.error( `${args.map.id}::err` ), context.t1*2+sessionDelay );
  }

}

startMultipleOptionStdioIgnore.rapidity = -1;
startMultipleOptionStdioIgnore.timeOut = 1e6;
startMultipleOptionStdioIgnore.description =
`
  - no problems in stdio:ignore mode
`

//

function kill( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  var expectedOutput = testAppPath + '\n';
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, kill child process using process descriptor`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o )

      _.time.out( context.t1*2, () => _.process.kill( o.pnd ) ) /* 1000 */

      returned.then( ( op ) =>
      {
        test.identical( op.exitCode, null );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, 'SIGKILL' );
        test.true( !_.strHas( op.output, 'Application timeout!' ) );
        return null;
      })

      return returned;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, kill child process using process id`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o )

      _.time.out( context.t1*2, () => _.process.kill( o.pnd.pid ) ) /* 1000 */

      returned.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
        }

        test.true( !_.strHas( op.output, 'Application timeout!' ) );
        return null;
      })

      return returned;
    })

    /* zzz for Vova : find how to simulate EPERM error using process.kill and write test case */

    return ready;
  }

  /* - */

  function testApp()
  {
    setTimeout( () =>
    {
      console.log( 'Application timeout!' )
    }, context.t2 ) /* 5000 */
  }
}

kill.timeOut = 16e4; /* Locally : 15.661s */

//

function killSync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;
  /*
    zzz : hangs up on Windows with interval below 150 if run in sync mode
  */

  function run( mode )
  {
    let ready = new _.Consequence().take( null );

    ready
    .then( () =>
    {
      test.case = `mode : ${mode}, kill child process using process descriptor`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready1 = _.process.startMinimal( o );

      ready1.then( ( op ) =>
      {
        /* Same result on Windows because process was killed using pnd, not pid */
        test.identical( op.exitCode, null );
        test.identical( op.exitSignal, 'SIGKILL' );
        test.identical( op.ended, true );
        test.true( !_.strHas( op.output, 'Application timeout!' ) );
        return null;
      })

      let ready2 = _.time.out( context.t1*2, () =>
      {
        let result = _.process.kill({ pnd : o.pnd, sync : 1 });
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.identical( result, true );
        return result;
      });

      return _.Consequence.And( ready1, ready2 );
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, kill child process using process id`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready1 = _.process.startMinimal( o )

      ready1.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGKILL' );
        }

        test.identical( op.ended, true );
        test.true( !_.strHas( op.output, 'Application timeout!' ) );
        return null;
      })

      let ready2 = _.time.out( context.t1*2, () =>
      {
        let result = _.process.kill({ pid : o.pnd.pid, sync : 1 });
        test.true( !_.process.isAlive( o.pnd.pid ) );
        test.identical( result, true );
        return result;
      })

      return _.Consequence.And( ready1, ready2 );
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = `mode:spawn, kill child process using process descriptor`
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o );

  //   ready1.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, null );
  //     test.identical( op.exitSignal, 'SIGKILL' );
  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pnd : o.pnd, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   });

  //   return _.Consequence.And( ready1, ready2 );
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = `mode:spawn, kill child process using process id`
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o )

  //   ready1.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.exitSignal, null );
  //     }
  //     else
  //     {
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGKILL' );
  //     }

  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pid : o.pnd.pid, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   })

  //   return _.Consequence.And( ready1, ready2 );
  // })

  // /* fork */

  // .then( () =>
  // {
  //   test.case = `mode:fork, kill child process using process descriptor`
  //   var o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o )

  //   ready1.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, null );
  //     test.identical( op.exitSignal, 'SIGKILL' );
  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pnd : o.pnd, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   })

  //   return _.Consequence.And( ready1, ready2 );
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = `mode:fork, kill child process using process id`

  //   var o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o )

  //   ready1.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.exitSignal, null );
  //     }
  //     else
  //     {
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGKILL' );
  //     }

  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pid : o.pnd.pid, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   })

  //   return _.Consequence.And( ready1, ready2 );
  // })

  // /* shell */

  // .then( () =>
  // {
  //   test.case = `mode:shell, kill child process using process descriptor`

  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'shell',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o )

  //   ready1.then( ( op ) =>
  //   {
  //     /* Same result on Windows because process was killed using pnd, not pid */
  //     test.identical( op.exitCode, null );
  //     test.identical( op.exitSignal, 'SIGKILL' );
  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pnd : o.pnd, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   })

  //   return _.Consequence.And( ready1, ready2 );
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = `mode:shell, kill child process using process id`

  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'shell',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready1 = _.process.start( o )

  //   ready1.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.exitSignal, null );
  //     }
  //     else
  //     {
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGKILL' );
  //     }

  //     test.identical( op.ended, true );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );

  //     return null;
  //   })

  //   let ready2 = _.time.out( context.t1*2, () =>
  //   {
  //     let result = _.process.kill({ pid : o.pnd.pid, sync : 1 });
  //     test.true( !_.process.isAlive( o.pnd.pid ) );
  //     test.identical( result, true );
  //     return result;
  //   })

  //   return _.Consequence.And( ready1, ready2 );
  // })

  /* */

  // return a.ready;

  /* - */

  function testApp()
  {
    setTimeout( () => { console.log( 'Application timeout!' ) }, context.t1*10 );
  }
}

killSync.timeOut = 5e5;

//

function killOptionWithChildren( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath2 = a.program( testApp2 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, child -> child, kill first child`;
      let testAppPath = a.program({ routine : testApp, locals : { mode } });
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'spawn',
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o );
      let lastChildPid, killed;

      o.pnd.on( 'message', ( e ) =>
      {
        lastChildPid = _.numberFrom( e );
        killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
      })

      returned.then( ( op ) =>
      {
        return killed.then( () =>
        {
          if( process.platform === 'win32' )
          {
            test.identical( op.exitCode, 1 );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, null );
          }
          else
          {
            test.identical( op.exitCode, null );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, 'SIGKILL' );
          }
          test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
          test.true( !_.process.isAlive( o.pnd.pid ) );
          test.true( !_.process.isAlive( lastChildPid ) );

          a.fileProvider.fileDelete( testAppPath );
          return null;
        })
      })

      return returned;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, child -> child, kill last child`;
      let testAppPath = a.program({ routine : testApp, locals : { mode } });
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'spawn',
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o );
      let lastChildPid, killed;

      o.pnd.on( 'message', ( e ) =>
      {
        lastChildPid = _.numberFrom( e );
        killed = _.process.kill({ pid : lastChildPid, withChildren : 1 });
      })

      returned.then( ( op ) =>
      {
        return killed.then( () =>
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
          test.true( !_.process.isAlive( o.pnd.pid ) );
          test.true( !_.process.isAlive( lastChildPid ) );

          a.fileProvider.fileDelete( testAppPath );
          return null;
        })
      })

      return returned;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, parent -> child*`;
      let testAppPath3 = a.program({ routine : testApp3, locals : { mode } });
      var o =
      {
        execPath : 'node ' + testAppPath3,
        mode : 'spawn',
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o );
      let children, killed;

      o.pnd.on( 'message', ( e ) =>
      {
        children = e.map( ( src ) => _.numberFrom( src ) )
        killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
      })

      returned.then( ( op ) =>
      {
        return killed.then( () =>
        {
          if( process.platform === 'win32' )
          {
            test.identical( op.exitCode, 1 );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, null );
          }
          else
          {
            test.identical( op.exitCode, null );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, 'SIGKILL' );
          }
          test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
          test.true( !_.process.isAlive( o.pnd.pid ) );
          test.true( !_.process.isAlive( children[ 0 ] ) )
          test.true( !_.process.isAlive( children[ 1 ] ) );

          a.fileProvider.fileDelete( testAppPath3 );
          return null;
        })
      })

      return returned;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, parent -> detached`;
      let testAppPath3 = a.program({ routine : testApp3, locals : { mode } });
      var o =
      {
        execPath : 'node ' + testAppPath3 + ' detached',
        mode : 'spawn',
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let returned = _.process.startMinimal( o );
      let children, killed;
      o.pnd.on( 'message', ( e ) =>
      {
        children = e.map( ( src ) => _.numberFrom( src ) )
        killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
      })

      returned.then( ( op ) =>
      {
        return killed.then( () =>
        {
          if( process.platform === 'win32' )
          {
            test.identical( op.exitCode, 1 );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, null );
          }
          else
          {
            test.identical( op.exitCode, null );
            test.identical( op.ended, true );
            test.identical( op.exitSignal, 'SIGKILL' );
          }
          test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
          test.true( !_.process.isAlive( o.pnd.pid ) );
          test.true( !_.process.isAlive( children[ 0 ] ) )
          test.true( !_.process.isAlive( children[ 1 ] ) );

          a.fileProvider.fileDelete( testAppPath3 );
          return null;
        })
      })

      return returned;
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, process is not running`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath2 : 'node ' + testAppPath2,
        mode,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );
      o.pnd.kill('SIGKILL');

      return o.ready.then( () =>
      {
        let ready = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
        return test.shouldThrowErrorAsync( ready );
      })

    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   test.case = 'child -> child, kill first child'
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready = _.process.start( o );
  //   let lastChildPid, killed;

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     lastChildPid = _.numberFrom( e );
  //     killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
  //   })

  //   a.ready.then( ( op ) =>
  //   {
  //     return killed.then( () =>
  //     {
  //       if( process.platform === 'win32' )
  //       {
  //         test.identical( op.exitCode, 1 );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, null );
  //       }
  //       else
  //       {
  //         test.identical( op.exitCode, null );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, 'SIGKILL' );
  //       }
  //       test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
  //       test.true( !_.process.isAlive( o.pnd.pid ) );
  //       test.true( !_.process.isAlive( lastChildPid ) );
  //       return null;
  //     })
  //   })

  //   return ready;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'child -> child, kill last child'
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready = _.process.start( o );
  //   let lastChildPid, killed;

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     lastChildPid = _.numberFrom( e );
  //     killed = _.process.kill({ pid : lastChildPid, withChildren : 1 });
  //   })

  //   ready.then( ( op ) =>
  //   {
  //     return killed.then( () =>
  //     {
  //       test.identical( op.exitCode, 0 );
  //       test.identical( op.ended, true );
  //       test.identical( op.exitSignal, null );
  //       test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
  //       test.true( !_.process.isAlive( o.pnd.pid ) );
  //       test.true( !_.process.isAlive( lastChildPid ) );
  //       return null;
  //     })
  //   })

  //   return ready;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'parent -> child*'
  //   var o =
  //   {
  //     execPath : 'node ' + testAppPath3,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready = _.process.start( o );
  //   let children, killed;

  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     children = e.map( ( src ) => _.numberFrom( src ) )
  //     killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
  //   })

  //   ready.then( ( op ) =>
  //   {
  //     return killed.then( () =>
  //     {
  //       if( process.platform === 'win32' )
  //       {
  //         test.identical( op.exitCode, 1 );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, null );
  //       }
  //       else
  //       {
  //         test.identical( op.exitCode, null );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, 'SIGKILL' );
  //       }
  //       test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
  //       test.true( !_.process.isAlive( o.pnd.pid ) );
  //       test.true( !_.process.isAlive( children[ 0 ] ) )
  //       test.true( !_.process.isAlive( children[ 1 ] ) );
  //       return null;
  //     })
  //   })

  //   return ready;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'parent -> detached'
  //   var o =
  //   {
  //     execPath : 'node ' + testAppPath3 + ' detached',
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready = _.process.start( o );
  //   let children, killed;
  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     children = e.map( ( src ) => _.numberFrom( src ) )
  //     killed = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
  //   })

  //   ready.then( ( op ) =>
  //   {
  //     return killed.then( () =>
  //     {
  //       if( process.platform === 'win32' )
  //       {
  //         test.identical( op.exitCode, 1 );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, null );
  //       }
  //       else
  //       {
  //         test.identical( op.exitCode, null );
  //         test.identical( op.ended, true );
  //         test.identical( op.exitSignal, 'SIGKILL' );
  //       }
  //       test.identical( _.strCount( op.output, 'Application timeout' ), 0 );
  //       test.true( !_.process.isAlive( o.pnd.pid ) );
  //       test.true( !_.process.isAlive( children[ 0 ] ) )
  //       test.true( !_.process.isAlive( children[ 1 ] ) );
  //       return null;
  //     })
  //   })

  //   return ready;
  // })

  // /* */

  // .then( () =>
  // {
  //   test.case = 'process is not running';
  //   var o =
  //   {
  //     execPath : 'node ' + testAppPath2,
  //     mode : 'spawn',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o );
  //   o.pnd.kill('SIGKILL');

  //   return o.ready.then( () =>
  //   {
  //     let ready = _.process.kill({ pid : o.pnd.pid, withChildren : 1 });
  //     return test.shouldThrowErrorAsync( ready );
  //   })

  // })

  // /* */

  // return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var o =
    {
      execPath : mode === 'fork' ? 'testApp2.js' : 'node testApp2.js',
      currentPath : __dirname,
      mode,
      stdio : 'inherit',
      outputPiping : 0,
      outputCollecting : 0,
      inputMirroring : 0,
      throwingExitCode : 0
    }
    _.process.startMinimal( o );
    process.send( o.pnd.pid )
  }

  function testApp2()
  {
    if( process.send )
    process.send( process.pid );
    setTimeout( () => { console.log( 'Application timeout' ) }, context.t2 ) /* 5000 */
  }

  function testApp3()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    let detaching = process.argv[ 2 ] === 'detached';
    var o1 =
    {
      execPath : mode === 'fork' ? 'testApp2.js' : 'node testApp2.js',
      currentPath : __dirname,
      mode,
      detaching,
      inputMirroring : 0,
      throwingExitCode : 0
    }
    _.process.startMinimal( o1 );
    var o2 =
    {
      execPath : mode === 'fork' ? 'testApp2.js' : 'node testApp2.js',
      currentPath : __dirname,
      mode,
      detaching,
      inputMirroring : 0,
      throwingExitCode : 0
    }
    _.process.startMinimal( o2 );
    process.send( [ o1.process.pid, o2.pnd.pid ] )
  }

}

killOptionWithChildren.timeOut = 13e4; /* Locally : 12.669s */

//

function startMinimalErrorAfterTerminationWithSend( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let track;

  let modes = [ 'fork', 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    track = [];

    var o =
    {
      execPath : mode !== 'fork' ? 'node' : null,
      args : [ testAppPath ],
      mode,
      ipc : 1,
    }

    _.process.on( 'uncaughtError', uncaughtError_functor( mode ) );

    let result = _.process.startMinimal( o );

    o.conStart.then( ( arg ) =>
    {
      track.push( 'conStart' );
      return null
    });

    o.conTerminate.finally( ( err, op ) =>
    {
      track.push( 'conTerminate' );
      test.identical( err, undefined );
      test.identical( op, o );
      test.identical( o.exitCode, 0 );

      test.description = 'Attempt to send data when ipc channel is closed';
      try
      {
        o.pnd.send( 1 );
      }
      catch( err )
      {
        console.log( err );
      }

/* happens on servers
--------------- uncaught error --------------->

 = Message of error#387
    Channel closed
    code : 'ERR_IPC_CHANNEL_CLOSED'
    Error starting the process
    Exec path : /Users/runner/Temp/ProcessBasic-2020-10-29-8-0-2-841-ad4.tmp/startErrorAfterTerminationWithSend/testApp.js
    Current path : /Users/runner/work/wProcess/wProcess

 = Beautified calls stack
    at ChildProcess.target.send (internal/child_process.js:705:16)
    at wConsequence.<anonymous> (/Users/runner/work/wProcess/wProcess/proto/wtools/abase/l4_process.test/Execution.test.s:24677:17) *
    at wConsequence.take (/Users/runner/work/wProcess/wProcess/node_modules/wConsequence/proto/wtools/abase/l9/consequence/Consequence.s:2669:8)
    at end3 (/Users/runner/work/wProcess/wProcess/proto/wtools/abase/l4_process/l3/Execution.s:783:20)
    at end2 (/Users/runner/work/wProcess/wProcess/proto/wtools/abase/l4_process/l3/Execution.s:734:12)
    at ChildProcess.handleClose (/Users/runner/work/wProcess/wProcess/proto/wtools/abase/l4_process/l3/Execution.s:845:7)
    at ChildProcess.emit (events.js:327:22)
    at maybeClose (internal/child_process.js:1048:16)
    at Process.ChildProcess._handle.onexit (internal/child_process.js:288:5)

    at Object.<anonymous> (/Users/runner/work/wProcess/wProcess/node_modules/wTesting/proto/wtools/atop/testing/entry/Exec:11:11)

 = Throws stack
    thrown at ChildProcess.handleError @ /Users/runner/work/wProcess/wProcess/proto/wtools/abase/l4_process/l3/Execution.s:865:13
    thrown at errRefine @ /Users/runner/work/wProcess/wProcess/node_modules/wTools/proto/wtools/abase/l0/l5/fErr.s:120:16

 = Process
    Current path : /Users/runner/work/wProcess/wProcess
    Exec path : /Users/runner/hostedtoolcache/node/14.14.0/x64/bin/node /Users/runner/work/wProcess/wProcess/node_modules/wTesting/proto/wtools/atop/testing/entry/Exec .run proto/** rapidity:-3

--------------- uncaught error ---------------<
*/

      return null;
    })

    return _.time.out( context.t2 * 2, () => /* 10000 */
    {
      test.identical( track, [ 'conStart', 'conTerminate', 'uncaughtError' ] );
      test.identical( o.ended, true );
      test.identical( o.state, 'terminated' );
      test.identical( o.error, null );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      test.identical( o.pnd.exitCode, 0 );
      test.identical( o.pnd.signalCode, null );
    });

  }

  /* - */

  function testApp()
  {
    setTimeout( () => {}, context.t1 ); /* 1000 */
  }

  function uncaughtError_functor( mode )
  {
    return function uncaughtError( e )
    {
      var exp =
  `
  Channel closed
  `
      if( process.platform === 'darwin' )
      exp += `code : 'ERR_IPC_CHANNEL_CLOSED'`
      test.identical( _.strCount( e.err.originalMessage, 'Error starting the process' ), 1 );
      _.errAttend( e.err );
      track.push( 'uncaughtError' );
      _.process.off( 'uncaughtError', uncaughtError );
    }
  }

}

startMinimalErrorAfterTerminationWithSend.description =
`
  - handleClose receive error after termination of the process
  - error caused by call o.pnd.send()
  - throws asynchronouse uncahught error
`

//

function startMinimalTerminateHangedWithExitHandler( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  /* signal handler of njs on Windows is defective */
  if( process.platform === 'win32' )
  return test.true( true );

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    test.case = `mode : ${mode}`;
    let ready = _.Consequence().take( null );

    /* mode::shell doesn't support ipc */
    if( mode === 'shell' )
    return test.true( true );

    ready
    .then( () =>
    {
      let time;
      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputPiping : 1,
        ipc : 1,
        outputCollecting : 1,
      }

      let con = _.process.startMinimal( o );

      o.pnd.on( 'message', () =>
      {
        time = _.time.now();
        _.process.terminate({ pnd : o.pnd, timeOut : context.t1*5 });
      })

      con.then( () =>
      {
        test.identical( o.exitCode, null );
        test.identical( o.exitSignal, 'SIGKILL' );
        test.true( !_.strHas( o.output, 'SIGTERM' ) );
        test.ge( _.time.now() - time, context.t1*5 );
        console.log( `time : ${_.time.spent( time )}` );
        return null;
      })

      return con;
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   let time;
  //   let o =
  //   {
  //     execPath : 'node ' + testAppPath,
  //     mode : 'spawn',
  //     throwingExitCode : 0,
  //     outputPiping : 1,
  //     ipc : 1,
  //     outputCollecting : 1,
  //   }

  //   let con = _.process.start( o );

  //   o.pnd.on( 'message', () =>
  //   {
  //     time = _.time.now();
  //     _.process.terminate({ pnd : o.pnd, timeOut : context.t1*5 });
  //   })

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, null );
  //     test.identical( o.exitSignal, 'SIGKILL' );
  //     test.true( !_.strHas( o.output, 'SIGTERM' ) );
  //     test.ge( _.time.now() - time, context.t1*5 );
  //     console.log( `time : ${_.time.spent( time )}` );
  //     return null;
  //   })

  //   return con;
  // })

  // /* */

  // .then( () =>
  // {
  //   let time;
  //   let o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     throwingExitCode : 0,
  //     outputPiping : 1,
  //     ipc : 1,
  //     outputCollecting : 1,
  //   }

  //   let con = _.process.start( o );

  //   o.pnd.on( 'message', () =>
  //   {
  //     time = _.time.now();
  //     _.process.terminate({ pnd : o.pnd, timeOut : context.t1*5 });
  //   })

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, null );
  //     test.identical( o.exitSignal, 'SIGKILL' );
  //     test.is( !_.strHas( o.output, 'SIGTERM' ) );
  //     test.ge( _.time.now() - time, context.t1*5 );
  //     console.log( `time : ${_.time.spent( time )}` );
  //     return null;
  //   })

  //   return con;
  // })

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.process._exitHandlerRepair();
    process.send( process.pid )
    let x = 0;
    while( 1 )
    {
      x += Math.cos( Math.random() );
      // console.log( _.time.now() );
    }
  }
}

startMinimalTerminateHangedWithExitHandler.timeOut = 15e4; /* Locally : 14.622s */

startMinimalTerminateHangedWithExitHandler.description =
`
  Test app - code that blocks event loop and appExitHandlerRepair called at start

  Will test:
    - Termination of child process using SIGINT signal after small delay
    - Termination of child process using SIGKILL signal after small delay

  Expected behaviour:
    - For SIGINT: Child was terminated with exitCode : 0, exitSignal : null
    - For SIGKILL: Child was terminated with exitCode : null, exitSignal : SIGKILL
    - No time out message in output
`

//

function startMinimalTerminateAfterLoopRelease( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  // if( process.platform === 'win32' )
  // {
  /* zzz: windows-kill doesn't work correctrly on node 14
  investigate if its possible to use process.kill instead of windows-kill
  */
  //   test.identical( 1, 1 )
  //   return;
  // }

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;

      let o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        throwingExitCode : 0,
        outputPiping : 0,
        ipc : 1,
        outputCollecting : 1,
      }

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication */
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) );

      let con = _.process.startMinimal( o );

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pnd : o.pnd, timeOut : context.t2 * 2 }); /* 10000 */
      })

      con.then( () =>
      {
        test.identical( o.exitCode, null );
        /* njs on Windows does not let to set custom signal handler properly */
        if( process.platform === 'win32' )
        test.identical( o.exitSignal, 'SIGTERM' );
        else
        test.identical( o.exitSignal, 'SIGKILL' );
        test.true( !_.strHas( o.output, 'SIGTERM' ) );
        test.true( !_.strHas( o.output, 'Exit after release' ) );

        return null;
      })

      return con;
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // .then( () =>
  // {
  //   let o =
  //   {
  //     execPath : 'node ' + testAppPath,
  //     mode : 'spawn',
  //     throwingExitCode : 0,
  //     outputPiping : 0,
  //     ipc : 1,
  //     outputCollecting : 1,
  //   }

  //   let con = _.process.start( o );

  //   o.pnd.on( 'message', () =>
  //   {
  //     _.process.terminate({ pnd : o.pnd, timeOut : context.t2 * 2 }); /* 10000 */
  //   })

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, null );
  //     /* njs on Windows does not let to set custom signal handler properly */
  //     if( process.platform === 'win32' )
  //     test.identical( o.exitSignal, 'SIGTERM' );
  //     else
  //     test.identical( o.exitSignal, 'SIGKILL' );
  //     test.true( !_.strHas( o.output, 'SIGTERM' ) );
  //     test.true( !_.strHas( o.output, 'Exit after release' ) );

  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // .then( () =>
  // {
  //   let o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     throwingExitCode : 0,
  //     outputPiping : 0,
  //     ipc : 1,
  //     outputCollecting : 1,
  //   }

  //   let con = _.process.start( o );

  //   o.pnd.on( 'message', () =>
  //   {
  //     _.process.terminate({ pnd : o.pnd, timeOut : context.t2 * 2 }); /* 10000 */
  //   })

  //   con.then( () =>
  //   {
  //     test.identical( o.exitCode, null );
  //     /* njs on Windows does not let to set custom signal handler properly */
  //     if( process.platform === 'win32' )
  //     test.identical( o.exitSignal, 'SIGTERM' );
  //     else
  //     test.identical( o.exitSignal, 'SIGKILL' );
  //     test.true( !_.strHas( o.output, 'SIGTERM' ) );
  //     test.true( !_.strHas( o.output, 'Exit after release' ) );

  //     return null;
  //   })

  //   return con;
  // })

  // /*  */

  // return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );

    _.include( 'wProcess' );
    _.process._exitHandlerRepair();
    let loop = true;
    setTimeout( () =>
    {
      loop = false;
    }, context.t2 ) /* 5000 */
    process.send( process.pid );
    while( loop )
    {
      loop = loop;
    }
    console.log( 'Exit after release' );
  }
}

startMinimalTerminateAfterLoopRelease.timeOut = 25e4; /* Locally : 24.941s */
startMinimalTerminateAfterLoopRelease.description =
`
  Test app - code that blocks event loop for short period of time and appExitHandlerRepair called at start

  Will test:
    - Termination of child process using SIGINT signal after small delay

  Expected behaviour:
    - Child was terminated after event loop release with exitCode : 0, exitSignal : null
    - Child process message should be printed
`

//

function endSignalsBasic( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let o3 =
  {
    outputPiping : 1,
    outputCollecting : 1,
    applyingExitCode : 0,
    throwingExitCode : 0,
    stdio : 'pipe',
  }

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGQUIT' ) ) ); /* xxx */
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGINT' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGTERM' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGHUP' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalKilling( mode, 'SIGKILL' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => terminate( mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => terminateShell( mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => kill( mode ) ) );
  return a.ready;

  /* --- */

  function signalTerminating( mode, signal )
  {
    let ready = _.Consequence().take( null );

    /* signals SIGHUP and SIGQUIT is not supported by njs on Windows */
    if( process.platform === 'win32' )
    if( signal === 'SIGHUP' || signal === 'SIGQUIT' )
    return ready;

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}`;

      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [],
        mode,
      }

      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        if( process.platform !== 'win32' )
        exp1 += `${signal}\n`

        var exp2 =
`program1:begin
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withSleep:1 withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1`, `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var time1 = _.time.now();
      var returned = _.process.startMinimal( options );
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
sleep:end
program1:end
`

        /* njs on Windows does killing */
        if( process.platform === 'win32' )
        exp1 =
`program1:begin
sleep:begin
`
        else
        exp1 += `${signal}\n`

        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        if( process.platform !== 'win32' )
        test.ge( dtime, context.t1 * 10 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withDeasync:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withDeasync:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
deasync:begin
`
        if( process.platform !== 'win32' )
        exp1 += `${signal}\n`

        var exp2 =
`program1:begin
deasync:begin
program1:end
deasync:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function signalKilling( mode, signal )
  {
    let ready = _.Consequence().take( null );

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var time1;
      var returned = _.process.startMinimal( options );
      _.time.out( context.t1 * 4, () =>
      {
        time1 = _.time.now();
        test.identical( options.pnd.killed, false );
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withSleep:1 withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1`, `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, ${signal}, withDeasync:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withDeasync:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
deasync:begin
`
        var exp2 =
`program1:begin
deasync:begin
program1:end
deasync:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function terminate( mode )
  {
    let ready = _.Consequence().take( null );

    if( mode === 'shell' )
    return ready;

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate`;

      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform !== 'win32' )
        exp1 += `SIGTERM\n`;
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withSleep:1 withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1`, `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1, timeOut : context.t1 * 4 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* kill without waiting in njs on Windows */
        if( process.platform !== 'win32' )
        test.ge( dtime, context.t1 * 4 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withDeasync:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withDeasync:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
deasync:begin
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform !== 'win32' )
        exp1 += `SIGTERM\n`;

        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function terminateShell( mode )
  {
    let ready = _.Consequence().take( null );

    /* if shell then parent process may ignore the signal */
    if( mode !== 'shell' )
    return ready;

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform !== 'win32' )
        exp1 += `SIGTERM\n`;

        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withSleep:1 withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1`, `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
sleep:end
program1:end
SIGTERM
`
        var exp2 =
`program1:begin
sleep:begin
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          /*
            on linux might be two processes( shell + node ), on mac shell has only node
            on linux might shell receives SIGTERM and kills node
            on mac node ignores SIGTERM because of sleep option enabled
          */
          if( process.platform === 'darwin' )
          test.identical( options.exitSignal, 'SIGKILL' );
          else
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.exitCode, null );
          if( process.platform === 'darwin' )
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          else
          test.identical( options.pnd.signalCode, 'SIGTERM' );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, terminate, withDeasync:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withDeasync:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
deasync:begin
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform !== 'win32' )
        exp1 += `SIGTERM\n`;
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function kill( mode )
  {
    let ready = _.Consequence().take( null );

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, kill, pid, withChildren:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, kill withTools:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd.pid );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, kill withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd.pid );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, kill withTools:1 withSleep:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withTools:1`, `withSleep:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd.pid );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
sleep:begin
`
        var exp2 =
`program1:begin
sleep:begin
sleep:end
program1:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* */

    .then( function( arg )
    {
      test.case = `mode:${mode}, kill withDeasync:1`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ `withDeasync:1` ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd.pid );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
deasync:begin
`
        var exp2 =
`program1:begin
deasync:begin
program1:end
deasync:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        /* if shell then parent process may ignore the signal */
        if( mode !== 'shell' )
        test.le( dtime, context.t1 * 2 );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function program1()
  {
    console.log( 'program1:begin' );

    let withSleep = process.argv.includes( 'withSleep:1' );
    let withTools = process.argv.includes( 'withTools:1' );
    let withDeasync = process.argv.includes( 'withDeasync:1' );

    // console.log( `withSleep:${withSleep} withTools:${withTools} withDeasync:${withDeasync}` );

    if( withTools || withDeasync )
    {
      let _ = require( toolsPath );
      _.include( 'wProcess' );
      _.process._exitHandlerRepair();
    }

    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 8 );

    if( withSleep )
    sleep( context.t1 * 10 );

    if( withDeasync )
    deasync( context.t1 * 10 );

    function onTime()
    {
      console.log( 'time:end' );
    }

    function sleep( delay )
    {
      console.log( 'sleep:begin' );
      let now = Date.now();
      while( ( Date.now() - now ) < delay )
      {
        let x = Number( '123' );
      }
      console.log( 'sleep:end' );
    }

    function deasync( delay )
    {
      let _ = wTools;
      console.log( 'deasync:begin' );
      let con = new _.Consequence().take( null );
      con.delay( delay ).deasync();
      console.log( 'deasync:end' );
    }

    function handlersRemove()
    {
      process.removeAllListeners( 'SIGHUP' );
      process.removeAllListeners( 'SIGINT' );
      process.removeAllListeners( 'SIGQUIT' );
      process.removeAllListeners( 'SIGTERM' );
      process.removeAllListeners( 'exit' );
    }

  }

}

endSignalsBasic.rapidity = -1 /* make it -2 later */
endSignalsBasic.timeOut = 1e7;
endSignalsBasic.description =
`
  - signals terminate or kill started process
`

/* zzz : find a way to really freeze a process to test routine _.process.terminate() with timeout */

//

function endSignalsOnExit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let o3 =
  {
    outputPiping : 1,
    outputCollecting : 1,
    applyingExitCode : 0,
    throwingExitCode : 0,
    stdio : 'pipe',
  }

  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGQUIT' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGINT' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGTERM' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGHUP' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalKilling( mode, 'SIGKILL' ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => terminate( mode ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => kill( mode ) ) );
  return a.ready;

  /* --- */

  function signalTerminating( mode, signal )
  {
    let ready = _.Consequence().take( null );

    /* signals SIGHUP and SIGQUIT is not supported by njs on Windows */
    if( process.platform === 'win32' )
    if( signal === 'SIGHUP' || signal === 'SIGQUIT' )
    return ready;

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, ${signal}`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
${signal}
exit:end
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
exit:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function signalKilling( mode, signal )
  {
    let ready = _.Consequence().take( null );

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, ${signal}`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
exit:end
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, signal );
        test.identical( options.ended, true );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.exitCode, null );
        test.identical( options.pnd.signalCode, signal );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function terminate( mode )
  {
    let ready = _.Consequence().take( null );

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, terminate, pid`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pid : options.pnd.pid, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
SIGTERM
exit:end
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        exp1 =
`program1:begin
`

        test.identical( options.output, exp1 );
        test.identical( _.strCount( options.output, 'exit:' ), process.platform === 'win32' ? 0 : 1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGTERM' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGTERM' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, terminate, native descriptor`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.terminate({ pnd : options.pnd, withChildren : 1 });
        return null;
      })
      returned.finally( function()
      {
        var exp =
`program1:begin
SIGTERM
exit:end
`
        if( process.platform === 'win32' )
        exp =
`program1:begin
`

        test.identical( options.output, exp );
        test.identical( _.strCount( options.output, 'exit:' ), process.platform === 'win32' ? 0 : 1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, true );

        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, 'SIGTERM' );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.pnd.signalCode, 'SIGTERM' );
        test.identical( options.pnd.exitCode, null );

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function kill( mode )
  {
    let ready = _.Consequence().take( null );

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, kill, pid`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd.pid );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
Killed
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, false );

        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, 1 );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, 1 );
        }
        else
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, 'SIGKILL' );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, 'SIGKILL' );
          test.identical( options.pnd.exitCode, null );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, kill, native descriptor`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 4, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        _.process.kill( options.pnd );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
Killed
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, true );

        test.identical( options.exitCode, null );
        test.identical( options.exitSignal, 'SIGKILL' );
        test.identical( options.exitReason, 'signal' );
        test.identical( options.pnd.signalCode, 'SIGKILL' );
        test.identical( options.pnd.exitCode, null );

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function program1()
  {

    console.log( 'program1:begin' );

    let withExitHandler = process.argv.includes( 'withExitHandler:1' );
    let withTools = process.argv.includes( 'withTools:1' );

    if( withTools )
    {
      let _ = require( toolsPath );
      _.include( 'wProcess' );
      _.process._exitHandlerRepair();
    }

    if( withExitHandler )
    process.once( 'exit', onExit );

    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 8 );

    function onTime()
    {
      console.log( 'time:end' );
    }

    function onExit()
    {
      console.log( 'exit:end' );
    }

  }

}

endSignalsOnExit.rapidity = -1;
endSignalsOnExit.timeOut = 1e7;
endSignalsOnExit.description =
`
  - handler of the event "exit" should be called, despite of signal, unless signal is SIGKILL
  - handler of the event "exit" should be called exactly once
`

//

function endSignalsOnExitExitAgain( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program1 );
  let o3 =
  {
    outputPiping : 1,
    outputCollecting : 1,
    applyingExitCode : 0,
    throwingExitCode : 0,
    stdio : 'pipe',
  }

  let modes = [ 'fork', 'spawn' ];
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGINT', 128 + 2 ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGQUIT', 128 + 3 ) ) );
  modes.forEach( ( mode ) => a.ready.then( () => signalTerminating( mode, 'SIGTERM', 128 + 15 ) ) );
  return a.ready;

  /* --- */

  function signalTerminating( mode, signal, exitCode )
  {
    let ready = _.Consequence().take( null );

    /* signals SIGHUP and SIGQUIT is not supported by njs on Windows */
    if( process.platform === 'win32' )
    if( signal === 'SIGHUP' || signal === 'SIGQUIT' )
    return ready;

    /* - */

    ready

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, withCode:0, ${signal}`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1', 'withCode:0' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 3, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp1 =
`program1:begin
${signal}
exit:${exitCode}
`
        /* poor implementation of signals in njs on Windows */
        if( process.platform === 'win32' )
        exp1 =
`program1:begin
`
        var exp2 =
`program1:begin
program1:end
exit:${exitCode}
`
        if( mode === 'shell' )
        test.true( options.output === exp1 || options.output === exp2 );
        else
        test.identical( options.output, exp1 );
        test.identical( _.strCount( options.output, 'exit:' ), process.platform === 'win32' ? 0 : 1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, true );

        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, signal );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, signal );
          test.identical( options.pnd.exitCode, null );
        }
        else
        {
          test.identical( options.exitCode, exitCode );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, exitCode );
        }

        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    .then( function( arg )
    {
      test.case = `mode:${mode}, withExitHandler:1, withTools:1, withCode:1, ${signal}`;
      var o2 =
      {
        execPath : mode === `fork` ? `${programPath}` : `node ${programPath}`,
        args : [ 'withExitHandler:1', 'withTools:1', 'withCode:1' ],
        mode,
      }
      var options = _.mapSupplement( null, o2, o3 );
      var returned = _.process.startMinimal( options );
      var time1;
      _.time.out( context.t1 * 3, () =>
      {
        test.identical( options.pnd.killed, false );
        time1 = _.time.now();
        options.pnd.kill( signal );
        return null;
      })
      returned.finally( function()
      {
        var exp =
`program1:begin
${signal}
exit:${exitCode}
`
        if( process.platform === 'win32' )
        exp =
`program1:begin
`
        test.identical( options.output, exp );

        /*
        Windows doesn't support signals handling, but will exit with signal if process was killed using pnd, exit event will not be emiited
        On Unix signal will be handled and process will exit with code passed to exit event handler
        */

        if( process.platform === 'win32' )
        {
          test.identical( options.exitCode, null );
          test.identical( options.exitSignal, signal );
          test.identical( options.exitReason, 'signal' );
          test.identical( options.pnd.signalCode, signal );
          test.identical( options.pnd.exitCode, null );
        }
        else
        {
          test.identical( options.exitCode, exitCode );
          test.identical( options.exitSignal, null );
          test.identical( options.exitReason, 'code' );
          test.identical( options.pnd.signalCode, null );
          test.identical( options.pnd.exitCode, exitCode );
        }

        test.identical( _.strCount( options.output, 'exit:' ),  process.platform === 'win32' ? 0 : 1 );
        test.identical( options.ended, true );
        test.identical( options.state, 'terminated' );
        test.identical( options.error, null );
        test.identical( options.pnd.killed, true );
        var dtime = _.time.now() - time1;
        console.log( `dtime:${dtime}` );
        return null;
      })

      return returned;
    })

    /* - */

    return ready;
  }

  /* -- */

  function program1()
  {

    console.log( 'program1:begin' );

    let withExitHandler = process.argv.includes( 'withExitHandler:1' );
    let withCode = process.argv.includes( 'withCode:1' );
    let withTools = process.argv.includes( 'withTools:1' );

    if( withTools )
    {
      let _ = require( toolsPath );
      _.include( 'wProcess' );
      _.process._exitHandlerRepair();
    }

    if( withExitHandler )
    {
      process.on( 'exit', onExit );
      process.on( 'exit', onExit2 );
    }

    setTimeout( () => { console.log( 'program1:end' ) }, context.t1 * 6 );

    function onExit2( exitCode )
    {
      console.log( `exit2:${exitCode}` );
    }

    function onExit( exitCode )
    {
      console.log( `exit:${exitCode}` );
      /* explicit call of process.exit() in exit handler cause problem with termination reason */
      if( withCode )
      process.exit( exitCode );
      else
      process.exit();
    }

  }

}

endSignalsOnExitExitAgain.description =
`
  - trait : explicit call of process.exit() in exit handler cause problem with termination reason
  - trait : explicit call of process.exit() in exit handler does not allow to call other exit handler
  - handler of the event "exit" should be executed on Unix
`

//

function terminate( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  a.ready.then( () => terminateCommon( 'spawn' ) )
  a.ready.then( () => terminateCommon( 'fork' ) )
  a.ready.then( () => terminateShell() )

  /* */

  return a.ready;

  /* - */

  function terminateCommon( mode )
  {
    let ready = new _.Consequence().take( null )

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using descriptor( pnd )`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pnd : o.pnd });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.identical( op.ended, true );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.identical( op.ended, true );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using pid`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate( o.pnd.pid );
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );/* 1 because process was killed using pid */
          test.identical( op.exitSignal, null );
          test.identical( op.ended, true );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.identical( op.ended, true );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using pid, zero time out`

      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pid : o.pnd.pid, timeOut : 0 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using pid, low time out`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pid : o.pnd.pid, timeOut : 1 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
          test.identical( op.ended, true );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.true( op.exitSignal === 'SIGKILL' || op.exitSignal === 'SIGTERM' );
          test.identical( op.ended, true );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using pnd, zero time out`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pnd : o.pnd, timeOut : 0 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      test.case = `mode:${mode}, terminate process using pnd, low time out`
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.on( 'message', () =>
      {
        _.process.terminate({ pnd : o.pnd, timeOut : context.t1*4 });
        // _.process.terminate({ pnd : o.pnd, timeOut : 1 }); /* yyy */
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.identical( op.ended, true );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' ); /* yyy xxx : sometimes SIGKILL */
          test.identical( op.ended, true );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    return ready;
  }

  /* - */

  function terminateShell()
  {
    let ready = new _.Consequence().take( null )

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate( o.pnd );
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );/* null because process was killed using pnd */
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate( o.pnd.pid );
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate({ pnd : o.pnd, timeOut : 0 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );/* null because process was killed using pnd */
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }

        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate({ pid : o.pnd.pid, timeOut : 0 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        return null;
      })

      return ready;
    })

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate({ pnd : o.pnd, timeOut : 1 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        return null;
      })

      return ready;
    })

    /* */

    .then( () =>
    {
      var o =
      {
        execPath :  'node ' + testAppPath,
        mode : 'shell',
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o )

      o.pnd.stdout.on( 'data', () =>
      {
        if( !_.strHas( o.output, 'ready' ) )
        return;
        _.process.terminate({ pid : o.pnd.pid, timeOut : 1 });
      })

      ready.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( _.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        return null;
      })

      return ready;
    })

    return ready;
  }

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.process._exitHandlerRepair();
    if( process.send )
    process.send( process.pid );
    else
    console.log( 'ready' );
    setTimeout( () =>
    {
      console.log( 'Application timeout!' )
    }, context.t2 ) /* 5000 */
  }
}

terminate.description =
`
Checks termination of the child process spawned with different modes.
- Terminates process using descriptor( pnd )
- Terminates process using pid
- Terminates process using zero timeout
- Terminates process using low timeout
`

//

function terminateSync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  let modes = [ 'fork', 'spawn', 'shell' ];

  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    /*
      For mode::shell
      zzz Vova: shell,exec modes have different behaviour on Windows,OSX and Linux
      look for solution that allow to have same behaviour on each mode
    */

    ready
    .then( () =>
    {
      test.case = `mode : ${mode}, terminate with pnd`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : mode === 'shell' ? null : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        if( mode === 'shell' )
        {
          test.identical( op.exitCode, null );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, 'SIGKILL' );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
          return null;
        }
        else
        {
          if( process.platform === 'win32' )
          {
            test.identical( op.ended, true );
            test.identical( op.exitCode, null );
            test.identical( op.exitSignal, 'SIGTERM' );
            test.true( !_.strHas( op.output, 'SIGTERM' ) );
            test.true( !_.strHas( op.output, 'Application timeout!' ) );
          }
          else
          {
            test.identical( op.ended, true );
            test.identical( op.exitCode, null );
            test.identical( op.exitSignal, 'SIGTERM' );
            test.true( !_.strHas( op.output, 'Application timeout!' ) );
          }
          return null;
        }
      })

      return _.time.out( context.t1*4, () =>
      {
        let options =
        {
          pnd : o.pnd,
          sync : 1,
          timeOut : mode === 'shell' ? 0 : context.t1 * 5, /* default is 5000 */
        }
        let result = _.process.terminate( options );
        test.identical( result, true );
        return o.conTerminate;
      })
    })

    /* */

    .then( () =>
    {
      test.case = `mode : ${mode}, terminate with pid`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        ipc : mode === 'shell' ? null : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      o.conTerminate.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.ended, true );
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
          test.true( !_.strHas( op.output, 'SIGTERM' ) );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        else
        {
          test.identical( op.ended, true );
          test.identical( op.exitCode, null );
          if( mode === 'shell' )
          test.identical( op.exitSignal, 'SIGKILL' );
          else
          test.identical( op.exitSignal, 'SIGTERM' );
          test.true( !_.strHas( op.output, 'Application timeout!' ) );
        }
        return null;
      })

      return _.time.out( context.t1*4, () =>
      {
        let options =
        {
          pid : o.pnd.pid,
          sync : 1,
          timeOut : mode === 'shell' ? 0 : context.t1 * 5, /* default is 5000 */
        }
        let result = _.process.terminate( options );
        test.identical( result, true );
        return o.conTerminate;
      })
    })

    return ready;
  }

  /* ORIGINAL */
  // a.ready

  // /* */

  // .then( () =>
  // {
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o );

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     else
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pnd : o.pnd, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  // /* */

  // .then( () =>
  // {
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o );

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.exitSignal, null );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     else
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pid : o.pnd.pid, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  // /* fork */

  // .then( () =>
  // {

  //   var o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o )

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.exitSignal, null );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     else
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pid : o.pnd.pid, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  // /* */

  // .then( () =>
  // {
  //   let ready = _.Consequence();

  //   var o =
  //   {
  //     execPath : testAppPath,
  //     mode : 'fork',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o )

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     else
  //     {
  //       test.identical( op.ended, true );
  //       test.identical( op.exitCode, null );
  //       test.identical( op.exitSignal, 'SIGTERM' );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pnd : o.pnd, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  // /* shell */

  // /*
  //   zzz Vova: shell,exec modes have different behaviour on Windows,OSX and Linux
  //   look for solution that allow to have same behaviour on each mode
  // */

  // .then( () =>
  // {

  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'shell',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o )

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, null );
  //     test.identical( op.ended, true );
  //     test.identical( op.exitSignal, 'SIGKILL' );
  //     test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //     test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pnd : o.pnd, timeOut : 0, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  // /* */

  // .then( () =>
  // {

  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath,
  //     mode : 'shell',
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   _.process.start( o )

  //   o.conTerminate.then( ( op ) =>
  //   {
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( op.exitCode, 1 );
  //       test.identical( op.ended, true );
  //       test.identical( op.exitSignal, null );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     else
  //     {
  //       test.identical( op.exitCode, null );
  //       test.identical( op.ended, true );
  //       test.identical( op.exitSignal, 'SIGKILL' );
  //       test.true( !_.strHas( op.output, 'SIGTERM' ) );
  //       test.true( !_.strHas( op.output, 'Application timeout!' ) );
  //     }
  //     return null;
  //   })

  //   return _.time.out( context.t1*4, () =>
  //   {
  //     let result = _.process.terminate({ pid : o.pnd.pid, timeOut : 0, sync : 1 });
  //     test.identical( result, true );
  //     return o.conTerminate;
  //   })
  // })

  /* */

  // return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.process._exitHandlerRepair();
    if( process.send )
    process.send( process.pid );
    else
    console.log( 'ready' );
    setTimeout( () =>
    {
      console.log( 'Application timeout!' )
    }, context.t1*15 ) /* 5000 */
  }
}

terminateSync.timeOut = 5e5;
terminateSync.description =
`
Checks termination of the child process spawned with different modes.
Terminate routine works in sync mode.
- Terminates process using descriptor( pnd )
- Terminates process using pid
- Terminates process using zero timeout
- Terminates process using low timeout
`

//


function terminateFirstChild( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;

      let testAppPath = a.program({ routine : program1, locals : { mode } });
      let testAppPath2 = a.program( program2 );

      let o =
      {
        execPath : mode === `fork` ? `program1.js` : `node program1.js`,
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let terminate = _.Consequence();

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        program2Pid = program2Pid.pid;
        console.log( `parentPid : ${o.pnd.pid}` );
        console.log( `childPid : ${program2Pid}` );
        test.true( _.process.isAlive( o.pnd.pid ) );
        test.true( _.process.isAlive( program2Pid ) );
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 0,
        })
      })

      o.conTerminate.then( () =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, 1 );
          test.identical( o.exitSignal, null );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.exitSignal, 'SIGTERM' );
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );

        if( mode === 'shell' )
        {
          test.identical( _.strCount( o.output, 'Time out!' ), 0 );
          /*
            On darwing program1 exists right after signal, program2 continues to work
            On win/linux program1 waits for termination of program2 because only shell was terminated
          */

          if( process.platform === 'darwin' )
          {
            test.identical( _.strCount( o.output, 'program2::end' ), 0 );
            test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
            test.true( _.process.isAlive( program2Pid ) );

            return _.time.out( context.t1*15, () =>
            {
              test.true( !_.process.isAlive( program2Pid ) );
              test.true( a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
              return null;
            });
          }
          else
          {
            test.identical( _.strCount( o.output, 'program2::end' ), 1 );
            test.true( a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
            test.true( !_.process.isAlive( program2Pid ) );
          }

          return null;
        }
        else
        {
          test.identical( _.strCount( o.output, 'program2::end' ), 0 );
          test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );

          /* platform::windows killls children processes, in contrast other platforms politely termonate children processes */
          if( process.platform === 'win32' )
          test.true( !_.process.isAlive( program2Pid ) );
          else
          test.true( _.process.isAlive( program2Pid ) );

          return _.time.out( context.t1*15 );
        }


      })

      if( mode !== 'shell' )
      {
        o.conTerminate.then( () =>
        {
          test.true( !_.process.isAlive( program2Pid ) );
          /* platform::windows killls children processes, in contrast other platforms politely termonate children processes */
          if( process.platform === 'win32' )
          test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
          else
          test.true( a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
          test.identical( _.strCount( o.output, 'exit' ), 0 );
          return null;
        })

      }
      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }


  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program2::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    console.log( `parentPid : ${process.pid}` );

    var o =
    {
      execPath : mode === 'fork' ? 'program2.js' : 'node program2.js',
      currentPath : __dirname,
      mode,
      stdio : 'pipe',
      inputMirroring : 0,
      outputPiping : 1,
      outputCollecting : 0,
      throwingExitCode : 0,
    }
    _.process.startMinimal( o );

    let timer;
    if( mode === 'shell' )
    timer = _.time.out( context.t1*25 );
    else
    timer = _.time.outError( context.t1*25 );

    console.log( 'program1::begin' );
  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    console.log( `childPid : ${process.pid}` );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
      _.fileProvider.fileWrite( _.path.join( __dirname, 'program2end' ), 'end' );
    }, context.t1*10 )

    process.on( 'exit', () =>
    {
      console.log( 'program2::exit' );
    })

    console.log( 'program2::begin' );

  }

}

terminateFirstChild.timeOut = 53e4; /* Locally : 52.720s */
terminateFirstChild.description =
`
modes : spawn, fork
terminate first child withChildren:0
first child with signal SIGTERM on unix and exit code 1 on win
second child continues to work
mode : shell
terminate first child
first child with signal SIGTERM on unix and exit code 1 on win
On darwing program1 exists right after signal, program2 continues to work
On win/linux program1 waits for termination of program2 because only shell was terminated

`

//


function terminateSecondChild( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;

      let testAppPath = a.program({ routine : program1, locals : { mode } });
      let testAppPath2 = a.program( program2 );

      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let terminate = _.Consequence();

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        program2Pid = program2Pid.pid;
        return _.process.terminate
        ({
          pid : program2Pid,
          timeOut : context.t1 * 5,
          withChildren : 0
        })
      })

      o.conTerminate.then( () =>
      {
        test.identical( o.exitCode, 0 );
        test.identical( o.exitSignal, null );

        let program2Op = _.fileProvider.fileRead({ filePath : a.abs( 'program2' ), encoding : 'json' });

        if( mode === 'shell' )
        {
          /* on windows and linux in mode::shell intermediate process could be created */
          if( process.platform !== 'linux' && process.platform !== 'win32' )
          test.identical( program2Op.pid, program2Pid );
        }
        else
        {
          test.identical( program2Op.pid, program2Pid );
        }

        if( process.platform === 'win32' )
        {
          test.identical( program2Op.exitCode, 1 );
          test.identical( program2Op.exitSignal, null );
        }
        else
        {
          if( mode === 'shell' )
          {
            /*
            if spawn does create second process in mode::shell then those checks are not relevant
            */
            if( !program2Op.exitCode )
            {
              test.identical( program2Op.exitCode, null );
              test.identical( program2Op.exitSignal, 'SIGTERM' );
            }
          }
          else
          {
            test.identical( program2Op.exitCode, null );
            test.identical( program2Op.exitSignal, 'SIGTERM' );
          }
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::end' ), 0 );

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }

  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program2::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var o =
    {
      execPath : mode === 'fork' ? 'program2.js' : 'node program2.js',
      currentPath : __dirname,
      mode,
      stdio : 'inherit',
      inputMirroring : 0,
      outputPiping : 0,
      outputCollecting : 0,
      throwingExitCode : 0,
    }
    _.process.startMinimal( o );

    let timer = _.time.outError( context.t1*25 );

    console.log( 'program1::begin' );

    o.conTerminate.thenGive( () =>
    {
      timer.error( _.dont );

      let data =
      {
        pid : o.pnd.pid,
        exitCode : o.exitCode,
        exitSignal : o.exitSignal
      }
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program2' ),
        data,
        encoding : 'json'
      })
    })
  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
    }, context.t1*10 )

    console.log( 'program2::begin' );

  }

}

terminateSecondChild.timeOut = 8e4; /* Locally : 7.309s */
terminateSecondChild.description =
`
terminate second child
first child exits as normal
second exits with signal SIGTERM on unix and exit code 1 on win
`

//

function terminateDetachedFirstChild( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;

      let testAppPath = a.program({ routine : program1, locals : { mode } });
      let testAppPath2 = a.program( program2 );

      let o =
      {
        execPath : 'node program1.js',
        currentPath : a.routinePath,
        mode : 'spawn',
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let terminate = _.Consequence();
      /* For mode::shell */
      let timerIsRunning;
      let timer;

      if( mode === 'shell' )
      {
        timerIsRunning = { isRunning : true };
        timer = waitForProgram2Ready( terminate, timerIsRunning );
      }
      else
      {
        o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );
      }

      terminate.then( () =>
      {
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        program2Pid = program2Pid.pid;
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 0
        })
      })

      o.conTerminate.then( () =>
      {
        if( mode === 'shell' )
        {
          if( timerIsRunning.isRunning )
          timer.cancel();
        }

        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, 1 );
          test.identical( o.exitSignal, null );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.exitSignal, 'SIGTERM' );
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        if( mode === 'shell' )
        test.ge( _.strCount( o.output, 'program2::begin' ), 0 );
        else
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::end' ), 0 );
        test.true( _.process.isAlive( program2Pid ) );

        return _.process.waitForDeath({ pid : program2Pid, timeOut : context.t1*15 });
      })

      o.conTerminate.then( () =>
      {
        test.true( !_.process.isAlive( program2Pid ) );
        test.true( a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }


  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program2::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function waitForProgram2Ready( terminate, timerIsRunning )
  {
    let filePath = a.abs( 'program2Pid' );
    return _.time.periodic( context.t1 / 2, () => /* 500 */
    {
      if( !a.fileProvider.fileExists( filePath ) )
      return true;
      timerIsRunning.isRunning = false;
      terminate.take( true );
    })
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var o =
    {
      execPath : mode === 'fork' ? 'program2.js' : 'node program2.js',
      currentPath : __dirname,
      mode,
      stdio : 'pipe',
      detaching : 1,
      inputMirroring : 0,
      outputPiping : 1,
      outputCollecting : 0,
      throwingExitCode : 0,
    }
    _.process.startMinimal( o );

    let timer = _.time.outError( context.t1*25 );

    console.log( 'program1::begin' );

  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program2end' ),
        data : 'end'
      })
    }, context.t1*10 )

    console.log( 'program2::begin' );

  }
}

terminateDetachedFirstChild.timeOut = 38e4; /* Locally : 37.294s */
terminateDetachedFirstChild.description =
`
program1 starts program2 in detached mode
tester terminates program1 with option withChildren : 0
program2 should continue to work
`

//

/* FOR MODE : FORK */
/* qqq for Vova : have a ( fast! ) look, please */
/*
 > program1.js
program1::begin
program2::begin
SIGTERM
--------------- uncaught error --------------->
 = Message of error#1
    IPC channel is already disconnected
    Error starting the process
        Exec path : program2.js
        Current path : /pro/Temp/ProcessBasic-2020-10-26-22-32-51-515-e694.tmp/terminateWithDetachedChildFork
 = Beautified calls stack
    at ChildProcess.target.disconnect (internal/child_process.js:832:26)
    at Pipe.channel.onread (internal/child_process.js:582:14)
 = Throws stack
    thrown at ChildProcess.handleError @ /wtools/abase/l4_process/l3/Execution.s:854:13
    thrown at errRefine @ /wtools/abase/l0/l5/fErr.s:120:16
 = Process
    Current path : /pro/Temp/ProcessBasic-2020-10-26-22-32-51-515-e694.tmp/terminateWithDetachedChildFork
    Exec path : /home/kos/.nvm/versions/node/v12.9.1/bin/node /pro/Temp/ProcessBasic-2020-10-26-22-32-51-515-e694.tmp/terminateWithDetachedChildFork/program1.js
--------------- uncaught error ---------------<
        - got :
          255
        - expected :
          null
        - difference :
          *
        /wtools/abase/l4_process.test/Execution.test.s:29900:12
          29896 :       test.identical( o.exitSignal, null );
          29897 :     }
          29898 :     else
          29899 :     {
        * 29900 :       test.identical( o.exitCode, null );
        Test check ( TestSuite::Tools.l4.ProcessBasic / TestRoutine::terminateWithDetachedChildFork /  # 1 ) ... failed
        - got :
          null
        - expected :
          'SIGTERM'
        - difference :
          *
        /wtools/abase/l4_process.test/Execution.test.s:29901:12
          29897 :     }
          29898 :     else
          29899 :     {
          29900 :       test.identical( o.exitCode, null );
        * 29901 :       test.identical( o.exitSignal, 'SIGTERM' );
*/

function terminateWithDetachedChild( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    } )

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;

      let testAppPath = a.program({ routine : program1, locals : { mode } });
      let testAppPath2 = a.program( program2 );

      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let terminate = _.Consequence();
      /* For mode::shell */
      let timerIsRunning;
      let timer;

      if( mode === 'shell' )
      {
        timerIsRunning = { isRunning : true };
        timer = waitForProgram2Ready( terminate, timerIsRunning );
      }
      else
      {
        o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );
      }

      terminate.then( () =>
      {
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        program2Pid = program2Pid.pid;
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 1
        })
      })

      o.conTerminate.then( () =>
      {
        if( mode === 'shell' )
        {
          if( timerIsRunning.isRunning )
          timer.cancel();
        }

        if( mode === 'fork' )
        {
          /*
          if both processes dies simultinously uncaught njs error can be thrown by the parent process:
          "IPC channel is already disconnected"
          */

          if( o.exitCode )
          {
            test.notIdentical( o.exitCode, 0 );
            test.identical( o.exitSignal, null );
          }
          else
          {
            test.identical( o.exitCode, null );
            test.identical( o.exitSignal, 'SIGTERM' );
          }
        }
        else
        {
          if( process.platform === 'win32' )
          {
            test.identical( o.exitCode, 1 );
            test.identical( o.exitSignal, null );
          }
          else
          {
            test.identical( o.exitCode, null );
            test.identical( o.exitSignal, 'SIGTERM' );
          }
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        if( mode === 'shell' )
        test.ge( _.strCount( o.output, 'program2::begin' ), 0 );
        else
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::end' ), 0 );
        test.identical( _.strCount( o.output, 'error' ), 0 );
        test.identical( _.strCount( o.output, 'Error' ), 0 );
        test.true( !_.process.isAlive( program2Pid ) );
        test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;

  }

  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program2::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function waitForProgram2Ready( terminate, timerIsRunning )
  {
    let filePath = a.abs( 'program2Pid' );
    return _.time.periodic( context.t1 / 2, () => /* 500 */
    {
      if( !a.fileProvider.fileExists( filePath ) )
      return true;
      timerIsRunning.isRunning = false;
      terminate.take( true );
    })
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var o =
    {
      execPath : mode === 'fork' ? 'program2.js' : 'node program2.js',
      currentPath : __dirname,
      mode,
      stdio : 'pipe',
      detaching : 1,
      inputMirroring : 0,
      outputPiping : 1,
      outputCollecting : 0,
      throwingExitCode : 0,
    }
    _.process.startMinimal( o );

    let timer = _.time.outError( context.t1*25 );

    console.log( 'program1::begin' );

  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program2end' ),
        data : 'end'
      })
    }, context.t1*10 )

    console.log( 'program2::begin' );

  }
}

terminateWithDetachedChild.timeOut = 9e4; /* Locally : 8.060s */
terminateWithDetachedChild.description =
`program1 starts program2 in detached mode
tester terminates program1 with option withChildren : 1
program1 and program2 should be terminated
`

//

function terminateSeveralChildren( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      let testAppPath = a.program( program1 );
      let testAppPath2 = a.program( program2 );
      let testAppPath3 = a.program( program3 );

      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let program3Pid = null;
      let terminate = _.Consequence({ capacity : 0 });

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        program2Pid = program2Pid.pid;
        program3Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program3Pid' ), encoding : 'json' });
        program3Pid = program3Pid.pid;
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 8,
          withChildren : 1
        })
      })

      o.conTerminate.then( () =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( o.exitCode, 1 );
          test.identical( o.exitSignal, null );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.exitSignal, 'SIGTERM' );
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::end' ), 0 );
        test.identical( _.strCount( o.output, 'program3::end' ), 0 );
        test.true( !_.process.isAlive( program2Pid ) );
        test.true( !_.process.isAlive( program3Pid ) );
        test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
        test.true( !a.fileProvider.fileExists( a.abs( 'program3end' ) ) );

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }

  /* ORIGINAL */
  // let o =
  // {
  //   execPath : 'node program1.js',
  //   currentPath : a.routinePath,
  //   mode : 'spawn',
  //   outputPiping : 1,
  //   outputCollecting : 1,
  //   throwingExitCode : 0
  // }

  // _.process.start( o );

  // let program2Pid = null;
  // let program3Pid = null;
  // let terminate = _.Consequence();

  // o.pnd.stdout.on( 'data', handleOutput );

  // terminate.then( () =>
  // {
  //   program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
  //   program2Pid = program2Pid.pid;
  //   program3Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program3Pid' ), encoding : 'json' });
  //   program3Pid = program3Pid.pid;
  //   return _.process.terminate
  //   ({
  //     pid : o.pnd.pid,
  //     timeOut : context.t1 * 8,
  //     withChildren : 1
  //   })
  // })

  // o.conTerminate.then( () =>
  // {
  //   if( process.platform === 'win32' )
  //   {
  //     test.identical( o.exitCode, 1 );
  //     test.identical( o.exitSignal, null );
  //   }
  //   else
  //   {
  //     test.identical( o.exitCode, null );
  //     test.identical( o.exitSignal, 'SIGTERM' );
  //   }

  //   test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program2::end' ), 0 );
  //   test.identical( _.strCount( o.output, 'program3::end' ), 0 );
  //   test.true( !_.process.isAlive( program2Pid ) );
  //   test.true( !_.process.isAlive( program3Pid ) );
  //   test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
  //   test.true( !a.fileProvider.fileExists( a.abs( 'program3end' ) ) );

  //   return null;
  // })

  // return _.Consequence.AndKeep( terminate, o.conTerminate );

  /*

       - got :
          255
        - expected :
          null
        - difference :
          *

        /pro/builder/proto/wtools/abase/l4_process.test/Execution.test.s:30821:12
          30817 :       test.identical( o.exitSignal, null );
          30818 :     }
          30819 :     else
          30820 :     {
        * 30821 :       test.identical( o.exitCode, null );

        Test check ( TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren /  # 1 ) ... failed
        - got :
          null
        - expected :
          'SIGTERM'
        - difference :
          *

        /pro/builder/proto/wtools/abase/l4_process.test/Execution.test.s:30822:12
          30818 :     }
          30819 :     else
          30820 :     {
          30821 :       test.identical( o.exitCode, null );
        * 30822 :       test.identical( o.exitSignal, 'SIGTERM' );

        Test check ( TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren /  # 2 ) ... failed
        - got :
          2
        - expected :
          1
        - difference :
          *

        /pro/builder/proto/wtools/abase/l4_process.test/Execution.test.s:30825:10
          30821 :       test.identical( o.exitCode, null );
          30822 :       test.identical( o.exitSignal, 'SIGTERM' );
          30823 :     }
          30824 :
        * 30825 :     test.identical( _.strCount( o.output, 'program1::begin' ), 1 );

        Test check ( TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren /  # 3 ) ... failed
        - got :
          1
        - expected :
          0
        - difference :
          *

        /pro/builder/proto/wtools/abase/l4_process.test/Execution.test.s:30828:10
          30824 :
          30825 :     test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
          30826 :     test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
          30827 :     test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
        * 30828 :     test.identical( _.strCount( o.output, 'program2::end' ), 0 );

        Test check ( TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren /  # 6 ) ... failed
        - got :
          1
        - expected :
          0
        - difference :
          *

        /pro/builder/proto/wtools/abase/l4_process.test/Execution.test.s:30829:10
          30825 :     test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
          30826 :     test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
          30827 :     test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
          30828 :     test.identical( _.strCount( o.output, 'program2::end' ), 0 );
        * 30829 :     test.identical( _.strCount( o.output, 'program3::end' ), 0 );

        Test check ( TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren /  # 7 ) ... failed
      Failed ( test routine time limit ) TestSuite::Tools.l4.porocess.Execution / TestRoutine::terminateSeveralChildren in 60.555s

  */

  /* - */

  function handleOutput( o, terminate )
  {
    if( !_.strHas( o.output, 'program2::begin' ) || !_.strHas( o.output, 'program3::begin' ) )
    return;

    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var o =
    {
      currentPath : __dirname,
      stdio : 'inherit',
      inputMirroring : 0,
      outputPiping : 0,
      outputCollecting : 0,
      throwingExitCode : 0,
    }

    _.process.startMinimal( _.mapExtend( null, o, { execPath : 'node program2.js', mode : 'spawn' }));
    _.process.startMinimal( _.mapExtend( null, o, { execPath : 'node program3.js', mode : 'spawn' }));

    let timer = _.time.outError( context.t1*32 );

    console.log( 'program1::begin' );
  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program2end' ),
        data : 'end'
      })
    }, context.t1*16 )

    console.log( 'program2::begin' );

  }

  /* - */

  function program3()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program3Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program3::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program3end' ),
        data : 'end'
      })
    }, context.t1*16 )

    console.log( 'program3::begin' );

  }

}

terminateSeveralChildren.timeOut = 9e4; /* Locally : 8.680s */

//

function terminateSeveralDetachedChildren( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      a.reflect();
      return null;
    })

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      let testAppPath = a.program( program1 );
      let testAppPath2 = a.program( program2 );
      let testAppPath3 = a.program( program3 );

      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      let program2Pid = null;
      let program3Pid = null;
      let terminate = _.Consequence({ capacity : 0 });

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        console.log( 'terminate' );
        program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
        console.log( 'program2Pid', program2Pid );
        program2Pid = program2Pid.pid;
        program3Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program3Pid' ), encoding : 'json' });
        console.log( 'program3Pid', program3Pid );
        program3Pid = program3Pid.pid;
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 1
        })
      })

      o.conTerminate.then( () =>
      {
        console.log( 'conTerminate' );

        if( process.platform === 'win32' )
        {
          test.notIdentical( o.exitCode, 0 ) /* returns 4294967295 which is -1 to uint32. */
          test.identical( o.exitSignal, null );
        }
        else
        {
          test.identical( o.exitCode, null );
          test.identical( o.exitSignal, 'SIGTERM' );
        }

        test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
        test.identical( _.strCount( o.output, 'program2::end' ), 0 );
        test.identical( _.strCount( o.output, 'program3::end' ), 0 );
        test.true( !_.process.isAlive( program2Pid ) );
        test.true( !_.process.isAlive( program3Pid ) );
        test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
        test.true( !a.fileProvider.fileExists( a.abs( 'program3end' ) ) );

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;

  }

  /* ORIGINAL */
  // let o =
  // {
  //   execPath : 'node program1.js',
  //   currentPath : a.routinePath,
  //   mode : 'spawn',
  //   outputPiping : 1,
  //   outputCollecting : 1,
  //   throwingExitCode : 0
  // }

  // _.process.start( o );

  // let program2Pid = null;
  // let program3Pid = null;
  // let terminate = _.Consequence();

  // o.pnd.stdout.on( 'data', handleOutput );

  // terminate.then( () =>
  // {
  //   console.log( 'terminate' );
  //   program2Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program2Pid' ), encoding : 'json' });
  //   console.log( 'program2Pid', program2Pid );
  //   program2Pid = program2Pid.pid;
  //   program3Pid = _.fileProvider.fileRead({ filePath : a.abs( 'program3Pid' ), encoding : 'json' });
  //   console.log( 'program3Pid', program3Pid );
  //   program3Pid = program3Pid.pid;
  //   return _.process.terminate
  //   ({
  //     pid : o.pnd.pid,
  //     timeOut : context.t1 * 5,
  //     withChildren : 1
  //   })
  // })

  // o.conTerminate.then( () =>
  // {
  //   console.log( 'conTerminate' );

  //   if( process.platform === 'win32' )
  //   {
  //     test.identical( o.exitCode, 1 );
  //     test.identical( o.exitSignal, null );
  //   }
  //   else
  //   {
  //     test.identical( o.exitCode, null );
  //     test.identical( o.exitSignal, 'SIGTERM' );
  //   }

  //   test.identical( _.strCount( o.output, 'program1::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program2::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program3::begin' ), 1 );
  //   test.identical( _.strCount( o.output, 'program2::end' ), 0 );
  //   test.identical( _.strCount( o.output, 'program3::end' ), 0 );
  //   test.true( !_.process.isAlive( program2Pid ) );
  //   test.true( !_.process.isAlive( program3Pid ) );
  //   test.true( !a.fileProvider.fileExists( a.abs( 'program2end' ) ) );
  //   test.true( !a.fileProvider.fileExists( a.abs( 'program3end' ) ) );

  //   return null;
  // })

  // return _.Consequence.AndKeep( terminate, o.conTerminate );

  /* - */

  function handleOutput( o, terminate )
  {
    if( !_.strHas( o.output, 'program2::begin' ) || !_.strHas( o.output, 'program3::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    var o =
    {
      currentPath : __dirname,
      stdio : 'pipe',
      inputMirroring : 0,
      outputPiping : 1,
      detaching : 1,
      outputCollecting : 0,
      throwingExitCode : 0,
    }

    _.process.startMinimal( _.mapExtend( null, o, { execPath : 'node program2.js', mode : 'spawn' }));
    _.process.startMinimal( _.mapExtend( null, o, { execPath : 'node program3.js', mode : 'spawn' }));

    let timer = _.time.outError( context.t1*25 );

    console.log( 'program1::begin' );
  }

  /* - */

  function program2()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program2Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program2::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program2end' ),
        data : 'end'
      })
    }, context.t1*10 )

    console.log( 'program2::begin' );

  }

  /* - */

  function program3()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );

    _.fileProvider.fileWrite
    ({
      filePath : _.path.join( __dirname, 'program3Pid' ),
      data : { pid : process.pid },
      encoding : 'json'
    })

    setTimeout( () =>
    {
      console.log( 'program3::end' );
      _.fileProvider.fileWrite
      ({
        filePath : _.path.join( __dirname, 'program3end' ),
        data : 'end'
      })
    }, context.t1*10 )

    console.log( 'program3::begin' );

  }

}

terminateSeveralDetachedChildren.timeOut = 8e4; /* Locally : 7.407s */
terminateSeveralDetachedChildren.description =
`
Program1 spawns two detached children.
Tester terminates Program1 with option withChildren:1
All three processes should be dead before timeOut.
`

//

function terminateDeadProcess( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      let o =
      {
        execPath : mode === 'fork' ? 'program1.js' : 'node program1.js',
        currentPath : a.routinePath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o );

      o.conTerminate.then( () =>
      {
        test.identical( o.exitCode, 0 )
        test.identical( o.exitSignal, null );
        return _.process.terminate({ pid : o.pnd.pid, withChildren : 0 });
      })

      o.conTerminate.then( ( got ) =>
      {
        test.identical( got, true );
        let con = _.process.terminate({ pid : o.pnd.pid, withChildren : 1 });
        return test.shouldThrowErrorAsync( con );
      })

      return o.conTerminate;
    })

    return ready;
  }

  /* ORIGINAL */
  // let o =
  // {
  //   execPath : 'node program1.js',
  //   currentPath : a.routinePath,
  //   mode : 'spawn',
  //   outputPiping : 1,
  //   outputCollecting : 1,
  //   throwingExitCode : 0
  // }

  // _.process.start( o );

  // o.conTerminate.then( () =>
  // {
  //   test.identical( o.exitCode, 0 )
  //   test.identical( o.exitSignal, null );
  //   return _.process.terminate({ pid : o.pnd.pid, withChildren : 0 });
  // })

  // o.conTerminate.then( ( got ) =>
  // {
  //   test.identical( got, true );
  //   let con = _.process.terminate({ pid : o.pnd.pid, withChildren : 1 });
  //   return test.shouldThrowErrorAsync( con );
  // })

  // return o.conTerminate;

  /* - */

  function program1()
  {
    console.log( 'program1::begin' );
    setTimeout( () =>
    {
      console.log( 'program1::begin' );
    }, context.t1 );
  }
}

terminateDeadProcess.description =
`
Terminated dead process.
Returns true with withChildren:0
Throws an error with withChildren:1
`

//

function terminateTimeOutNoHandler( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o )
      let terminate = _.Consequence();

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 0
        })
      })

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.ended, true );

        /* interpreter::njs on platform::Windows does not suppport signals, but has its own non-standard implementation */
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGTERM' );
        }

        test.identical( _.strCount( op.output, 'SIGTERM' ), 0 );
        test.identical( _.strCount( op.output, 'program1::begin' ), 1 );

        /*
          mode::shell
          Single process on darwin, Two processes on linux and windows
          Child continues to work on linux/windows
        */
        if( mode === 'shell' )
        {
          if( process.platform === 'darwin' )
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
          else
          test.identical( _.strCount( op.output, 'program1::end' ), 1 );
        }
        else
        {
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
        }

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }

  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program1::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 15 );

    console.log( 'program1::begin' );
  }
}

terminateTimeOutNoHandler.description =
`
Program1 has no SIGTERM handler.
Should terminate before timeOut with SIGTERM on unix and exit code 1 on win
`

//

function terminateTimeOutIgnoreSignal( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* - */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o )
      let terminate = _.Consequence();

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : context.t1 * 5,
          withChildren : 0
        })
      })

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.ended, true );

        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
          test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
        }
        else
        {
          test.identical( op.exitCode, null );
          /*
            On linux in mode::shell, process exits with SIGTERM instead of SIGKILL
            SIGTERM handler is not executed
          */
          if( process.platform === 'linux' && mode === 'shell' )
          {
            test.identical( op.exitSignal, 'SIGTERM' );
            test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
          }
          else
          {
            test.identical( op.exitSignal, 'SIGKILL' );
            test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 1 );
          }
        }

        test.identical( _.strCount( op.output, 'program1::begin' ), 1 );

        /*
          mode::shell
          Single process on darwin, Two processes on linux and windows
          Child continues to work on linux/windows
        */
        if( mode === 'shell' )
        {
          if( process.platform === 'darwin' )
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
          else
          test.identical( _.strCount( op.output, 'program1::end' ), 1 );
        }
        else
        {
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
        }

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }

  /* ORIGINAL */
  // var o =
  // {
  //   execPath :  'node ' + testAppPath,
  //   mode : 'spawn',
  //   outputPiping : 1,
  //   outputCollecting : 1,
  //   throwingExitCode : 0
  // }

  // _.process.start( o )
  // let terminate = _.Consequence();

  // o.pnd.stdout.on( 'data', handleOutput );

  // terminate.then( () =>
  // {
  //   return _.process.terminate
  //   ({
  //     pid : o.pnd.pid,
  //     timeOut : context.t1 * 5,
  //     withChildren : 0
  //   })
  // })

  // o.conTerminate.then( ( op ) =>
  // {
  //   test.identical( op.ended, true );

  //   if( process.platform === 'win32' )
  //   {
  //     test.identical( op.exitCode, 1 );
  //     test.identical( op.exitSignal, null );
  //     test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
  //   }
  //   else
  //   {
  //     test.identical( op.exitCode, null );
  //     test.identical( op.exitSignal, 'SIGKILL' );
  //     test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 1 );
  //   }

  //   test.identical( _.strCount( op.output, 'program1::begin' ), 1 );
  //   test.identical( _.strCount( op.output, 'program1::end' ), 0 );

  //   return null;
  // })

  // return _.Consequence.AndKeep( terminate, o.conTerminate );

  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program1::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    process.on( 'SIGTERM', () =>
    {
      console.log( 'program1::SIGTERM' )
    })

    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 15 );

    console.log( 'program1::begin' );
  }
}

terminateTimeOutIgnoreSignal.timeOut = 19e4; /* Locally : 18.401s */
terminateTimeOutIgnoreSignal.description =
`
Program1 has SIGTERM handler that ignores signal.
Should terminate after timeOut with SIGKILL on unix and exit code 1 on win
Windows doesn't support signals
`

//

function terminateZeroTimeOut( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready.then( () =>
    {
      test.case = `mode : ${mode}`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath,
        mode,
        outputPiping : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      _.process.startMinimal( o )
      let terminate = _.Consequence();

      o.pnd.stdout.on( 'data', _.routineJoin( null, handleOutput, [ o, terminate ] ) );

      terminate.then( () =>
      {
        return _.process.terminate
        ({
          pid : o.pnd.pid,
          timeOut : 0,
          withChildren : 0
        })
      })

      o.conTerminate.then( ( op ) =>
      {
        test.identical( op.ended, true );

        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.exitSignal, null );
        }
        else
        {
          test.identical( op.exitCode, null );
          test.identical( op.exitSignal, 'SIGKILL' );
        }

        test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
        test.identical( _.strCount( op.output, 'program1::begin' ), 1 );

        /*
          mode::shell
          Single process on darwin, Two processes on linux and windows
          Child continues to work on linux/windows
        */
        if( mode === 'shell' )
        {
          if( process.platform === 'darwin' )
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
          else
          test.identical( _.strCount( op.output, 'program1::end' ), 1 );
        }
        else
        {
          test.identical( _.strCount( op.output, 'program1::end' ), 0 );
        }

        return null;
      })

      return _.Consequence.AndKeep( terminate, o.conTerminate );
    })

    return ready;
  }

  /* - */

  function handleOutput( o, terminate, output )
  {
    if( !_.strHas( output.toString(), 'program1::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    process.on( 'SIGTERM', () =>
    {
      console.log( 'program1::SIGTERM' )
    })

    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 15 );

    console.log( 'program1::begin' );
  }
}

terminateZeroTimeOut.description =
`
Program1 has SIGTERM handler that ignores signal.
Should terminate right after call with SIGKILL on unix and exit code 1 on win
Signal handler should not be executed
`

//

function terminateZeroTimeOutWithoutChildrenShell( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );

  /* - */

  var o =
  {
    execPath : 'node program1',
    currentPath : a.routinePath,
    mode : 'shell',
    outputPiping : 1,
    outputCollecting : 1,
    throwingExitCode : 0
  }

  _.process.startMinimal( o )
  let terminate = _.Consequence();

  o.pnd.stdout.on( 'data', handleOutput );

  terminate.then( () =>
  {
    return _.process.terminate
    ({
      pid : o.pnd.pid,
      timeOut : 0,
      withChildren : 0
    })
  })

  o.conTerminate.then( ( op ) =>
  {
    test.identical( op.ended, true );

    if( process.platform === 'win32' )
    {
      test.identical( op.exitCode, 1 );
      test.identical( op.exitSignal, null );
    }
    else
    {
      test.identical( op.exitCode, null );
      test.identical( op.exitSignal, 'SIGKILL' );
    }

    test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
    test.identical( _.strCount( op.output, 'program1::begin' ), 1 );

    /*
      Single process on darwin, Two processes on linux and windows
      Child continues to work on linux/windows
    */
    if( process.platform === 'darwin' )
    test.identical( _.strCount( op.output, 'program1::end' ), 0 );
    else
    test.identical( _.strCount( op.output, 'program1::end' ), 1 );

    return null;
  })

  return _.Consequence.AndKeep( terminate, o.conTerminate );

  /* - */

  function handleOutput()
  {
    if( !_.strHas( o.output, 'program1::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    process.on( 'SIGTERM', () =>
    {
      console.log( 'program1::SIGTERM' )
    })

    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 15 );

    console.log( 'program1::begin' );
  }
}

terminateZeroTimeOutWithoutChildrenShell.description =
`
Program1 has SIGTERM handler that ignores signal.
Should terminate right after call with SIGKILL on unix and exit code 1 on win
On darwin node exists right after signal, because it is a single process
On unix/windows shell is spawned in addition to node process, so node continues to work after signal
Signal handler should not be executed
`

function terminateZeroTimeOutWithChildrenShell( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( program1 );

  /* - */

  var o =
  {
    execPath : 'node program1',
    currentPath : a.routinePath,
    mode : 'shell',
    outputPiping : 1,
    outputCollecting : 1,
    throwingExitCode : 0
  }

  _.process.startMinimal( o )
  let terminate = _.Consequence();

  o.pnd.stdout.on( 'data', handleOutput );

  terminate.then( () =>
  {
    return _.process.terminate
    ({
      pid : o.pnd.pid,
      timeOut : 0,
      withChildren : 1
    })
  })

  o.conTerminate.then( ( op ) =>
  {
    test.identical( op.ended, true );

    if( process.platform === 'win32' )
    {
      test.identical( op.exitCode, 1 );
      test.identical( op.exitSignal, null );
    }
    else
    {
      test.identical( op.exitCode, null );
      test.identical( op.exitSignal, 'SIGKILL' );
    }

    test.identical( _.strCount( op.output, 'program1::SIGTERM' ), 0 );
    test.identical( _.strCount( op.output, 'program1::begin' ), 1 );
    test.identical( _.strCount( op.output, 'program1::end' ), 0 );

    return null;
  })

  return _.Consequence.AndKeep( terminate, o.conTerminate );

  /* - */

  function handleOutput()
  {
    if( !_.strHas( o.output, 'program1::begin' ) )
    return;
    o.pnd.stdout.removeListener( 'data', handleOutput );
    terminate.take( null );
  }

  /* - */

  function program1()
  {
    process.on( 'SIGTERM', () =>
    {
      console.log( 'program1::SIGTERM' )
    })

    setTimeout( () =>
    {
      console.log( 'program1::end' );
    }, context.t1 * 15 );

    console.log( 'program1::begin' );
  }
}

terminateZeroTimeOutWithChildrenShell.description =
`
Program1 has SIGTERM handler that ignores signal.
Should terminate right after call with SIGKILL on unix and exit code 1 on win
On darwin node exists right after signal, because it is a single process
On unix/windows shell is spawned in addition to node process, so node continues to work after signal
Signal handler should not be executed
`

//

function terminateDifferentStdio( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, inherit`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath :  'node ' + testAppPath,
        mode,
        stdio : 'inherit',
        ipc : 1,
        outputPiping : 0,
        outputCollecting : 0,
        throwingExitCode : 0
      }

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication. */
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

      _.process.startMinimal( o )

      let ready = _.Consequence();

      o.pnd.on( 'message', () =>
      {
        ready.take( _.process.terminate( o.pnd.pid ) )
      })

      o.conTerminate.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        else
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        return null;
      })

      return _.Consequence.And( ready, o.conTerminate );
    })

    /* - */

    .then( () =>
    {
      test.case = `mode : ${mode}, ignore`;
      /*
        Phantom fail on Windows:

        Fail #1:
        signalSend : 544 name: node.exe
        signalSend : 552 name: csrss.exe
        ...
          = Message of error#1
            kill EPERM
            errno : 'EPERM'
            code : 'EPERM'
            syscall : 'kill'
            Current process does not have permission to kill target process 544

          = Beautified calls stack
            at process.kill (internal/process/per_thread.js:189:13)
            at signalSend (C:\Work\modules\wProcess\proto\wtools\abase\l4_process\l3\Execution.s:2851:15)
        ...

        Fail#2
        signalSend : 5164 name: node.exe
        signalSend : 544 name: conhost.exe
        signalSend : 552 name: csrss.exe
        ...
        = Message of error#1
          kill EPERM
          errno : 'EPERM'
          code : 'EPERM'
          syscall : 'kill'
          Current process does not have permission to kill target process 5164

        = Beautified calls stack
          at process.kill (internal/process/per_thread.js:189:13)
          at signalSend (C:\Work\modules\wProcess\proto\wtools\abase\l4_process\l3\Execution.s:2851:15)
        ...
      */

      var o =
      {
        execPath : mode === 'fork' ? testAppPath :  'node ' + testAppPath,
        mode,
        stdio : 'ignore',
        ipc : 1,
        outputPiping : 0,
        outputCollecting : 0,
        throwingExitCode : 0
      }

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication. */
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

      _.process.startMinimal( o )

      let ready = _.Consequence();

      o.pnd.on( 'message', () =>
      {
        ready.take( _.process.terminate( o.pnd.pid ) )
        /* xxx : possible solution for phantom problem on Windows */
        // ready.take( _.process.terminate({ pid : o.pnd.pid, ignoringErrorPerm : 1 }) )
      })

      o.conTerminate.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        else
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        return null;
      })

      return _.Consequence.And( ready, o.conTerminate );
    })

    /* - */

    .then( () =>
    {
      test.case = `mode : ${mode}, pipe`;
      var o =
      {
        execPath : mode === 'fork' ? testAppPath :  'node ' + testAppPath,
        mode,
        stdio : 'pipe',
        ipc : 1,
        throwingExitCode : 0
      }

      if( mode === 'shell' ) /* Mode::shell doesn't support inter process communication. */
      return test.shouldThrowErrorSync( () => _.process.startMinimal( o ) )

      _.process.startMinimal( o )

      let ready = _.Consequence();

      o.pnd.on( 'message', () =>
      {
        ready.take( _.process.terminate( o.pnd.pid ) )
      })

      o.conTerminate.then( ( op ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( op.exitCode, 1 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( !a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        else
        {
          test.identical( op.exitCode, 0 );
          test.identical( op.ended, true );
          test.identical( op.exitSignal, null );
          test.true( a.fileProvider.fileExists( a.abs( a.routinePath, o.pnd.pid.toString() ) ) );
        }
        return null;
      })

      return _.Consequence.And( ready, o.conTerminate );
    })

    /* */

    return ready;
  }

  /* - */

  function testApp()
  {
    process.on( 'SIGTERM', () =>
    {
      var fs = require( 'fs' );
      var path = require( 'path' )
      fs.writeFileSync( path.join( __dirname, process.pid.toString() ), process.pid.toString() );
      process.exit( 0 );
    })
    setTimeout( () =>
    {
      process.exit( -1 );
    }, context.t2 ) /* 5000 */
    process.send( 'ready' );
  }
}

terminateDifferentStdio.timeOut = 3e5;

//

/* zzz for Vova : extend, cover kill of group of processes */

function killComplex( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let modes = [ 'fork', 'spawn', 'shell' ];
  modes.forEach( ( mode ) => a.ready.then( () => run( mode ) ) );
  return a.ready;

  /* */

  function run( mode )
  {
    let ready = _.Consequence().take( null );
    let testAppPath2 = a.program({ routine : testApp2, locals : { mode } });

    ready

    .then( () =>
    {
      test.case = `mode : ${mode}, Kill child of child process`;
      var o =
      {
        execPath : 'node ' + testAppPath2,
        mode : 'spawn',
        ipc : 1,
        outputCollecting : 1,
        throwingExitCode : 0
      }

      let ready = _.process.startMinimal( o );

      let pid = null;
      let childOfChild = null;
      o.pnd.on( 'message', ( e ) =>
      {
        if( !pid )
        {
          pid = _.numberFrom( e )
          _.process.kill( pid );
        }
        else
        {
          childOfChild = e;
        }
      })

      ready.then( ( op ) =>
      {
        test.identical( op.exitCode, 0 );
        test.identical( op.ended, true );
        test.identical( op.exitSignal, null );
        test.identical( childOfChild.pid, pid );
        if( process.platform === 'win32' )
        {
          test.identical( childOfChild.exitCode, 1 );
          test.identical( childOfChild.exitSignal, null );
        }
        else
        {
          test.identical( childOfChild.exitCode, null );
          test.identical( childOfChild.exitSignal, 'SIGKILL' );
        }

        a.fileProvider.fileDelete( testAppPath2 );
        return null;
      })

      return ready;
    })

    /* */

    return ready;
  }

  /* ORIGINAL */
  // a.ready
  // .then( () =>
  // {
  //   test.case = 'Kill child of child process'
  //   var o =
  //   {
  //     execPath :  'node ' + testAppPath2,
  //     mode : 'spawn',
  //     ipc : 1,
  //     outputCollecting : 1,
  //     throwingExitCode : 0
  //   }

  //   let ready = _.process.start( o );

  //   let pid = null;
  //   let childOfChild = null;
  //   o.pnd.on( 'message', ( e ) =>
  //   {
  //     if( !pid )
  //     {
  //       pid = _.numberFrom( e )
  //       _.process.kill( pid );
  //     }
  //     else
  //     {
  //       childOfChild = e;
  //     }
  //   })

  //   ready.then( ( op ) =>
  //   {
  //     test.identical( op.exitCode, 0 );
  //     test.identical( op.ended, true );
  //     test.identical( op.exitSignal, null );
  //     test.identical( childOfChild.pid, pid );
  //     if( process.platform === 'win32' )
  //     {
  //       test.identical( childOfChild.exitCode, 1 );
  //       test.identical( childOfChild.exitSignal, null );
  //     }
  //     else
  //     {
  //       test.identical( childOfChild.exitCode, null );
  //       test.identical( childOfChild.exitSignal, 'SIGKILL' );
  //     }

  //     return null;
  //   })

  //   return ready;
  // })

  // /* */

  // return a.ready;

  /* - */

  function testApp()
  {
    setTimeout( () =>
    {
      console.log( 'Application timeout!' )
    }, context.t2 / 2 ) /* 2500 */
  }

  function testApp2()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var testAppPath = _.fileProvider.path.nativize( _.path.join( __dirname, 'testApp.js' ) );
    var o = { execPath : mode === 'fork' ? testAppPath : 'node ' + testAppPath, mode, throwingExitCode : 0 }
    var ready = _.process.startMinimal( o )
    process.send( o.pnd.pid );
    ready.then( ( op ) =>
    {
      process.send({ exitCode : o.exitCode, pid : o.pnd.pid, exitSignal : o.exitSignal })
      return null;
    })
    return ready;
  }

}

//

function execPathOf( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  /* zzz : implement for linux and osx */
  if( process.platform !== 'win32' )
  {
    test.identical( 1,1 );
    return;
  }

  a.ready

  /* */

  .then( () =>
  {
    let o = { execPath : testAppPath };
    _.process.startNjs( o )

    o.conStart.then( () => _.process.execPathOf( o.pnd ) )
    o.conStart.then( ( arg ) =>
    {
      test.true( _.strHas( arg, o.execPath ) );
      return null;
    })

    return _.Consequence.And( o.conStart, o.conTerminate );
  })

  /* */

  return a.ready;

  /* */

  function testApp()
  {
    setTimeout( () => {}, context.t1 * 5 ) /* 5000 */
  }
}

//

function waitForDeath( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );

  a.ready

  /* */

  .then( () =>
  {
    test.case = 'child process terminates by its own, wait for termination using pnd'
    let o =
    {
      execPath : 'node ' + testAppPath,
      throwingExitCode : 0,
      mode : 'spawn',
      stdio : 'pipe',
      outputPiping : 1,
      outputCollecting : 1
    };
    _.process.startMinimal( o )

    let terminated = _.process.waitForDeath({ pnd : o.pnd, timeOut : context.t1 * 10 })
    .then( () =>
    {
      test.identical( _.strCount( o.output, 'program::end' ), 1 );
      test.identical( o.state, 'terminated' );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      return null;
    })

    return _.Consequence.And( terminated, o.conTerminate );
  })

  /* */

  .then( () =>
  {
    test.case = 'child process terminates by its own, wait for termination using pid'
    let o =
    {
      execPath : 'node ' + testAppPath,
      throwingExitCode : 0,
      mode : 'spawn',
      stdio : 'pipe',
      outputPiping : 1,
      outputCollecting : 1
    };
    _.process.startMinimal( o )

    let terminated = _.process.waitForDeath({ pid : o.pnd.pid, timeOut : context.t1 * 10 })
    .then( () =>
    {
      test.identical( _.strCount( o.output, 'program::end' ), 1 );
      test.identical( o.state, 'terminated' );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      return null;
    })

    return _.Consequence.And( terminated, o.conTerminate );
  })

  /* */

  .then( () =>
  {
    test.case = 'child process is terminated by SIGTERM'
    let o =
    {
      execPath : 'node ' + testAppPath,
      throwingExitCode : 0,
      mode : 'spawn',
      stdio : 'pipe',
      outputPiping : 1,
      outputCollecting : 1
    };
    _.process.startMinimal( o )

    let terminated = _.process.waitForDeath({ pnd : o.pnd, timeOut : context.t1 * 10 })
    .then( () =>
    {
      test.identical( _.strCount( o.output, 'program::end' ), 0 );
      test.identical( o.state, 'terminated' );
      test.notIdentical( o.exitCode, 0 );
      test.notIdentical( o.exitSignal, null );
      return null;
    })

    /* njs on Windows kills child proecess instantly, without any delay */
    o.conStart.thenGive( () => o.pnd.kill( 'SIGTERM' ) )

    return _.Consequence.And( terminated, o.conTerminate );
  })

  /* */

  .then( () =>
  {
    test.case = 'process is still alive after timeOut'
    let o =
    {
      execPath : 'node ' + testAppPath,
      throwingExitCode : 0,
      mode : 'spawn',
      stdio : 'pipe',
      outputPiping : 1,
      outputCollecting : 1
    };
    _.process.startMinimal( o )

    let terminated = _.process.waitForDeath({ pnd : o.pnd, timeOut : context.t1 }) /* 1000 */
    terminated = test.shouldThrowErrorAsync( terminated, ( err ) =>
    {
      test.true( _.errIs( err ) );
      test.identical( err.reason, 'time out' );
    });

    o.conTerminate.then( () =>
    {
      test.identical( _.strCount( o.output, 'program::end' ), 1 );
      test.identical( o.state, 'terminated' );
      test.identical( o.exitCode, 0 );
      test.identical( o.exitSignal, null );
      return null;
    })

    return _.Consequence.And( terminated, o.conTerminate );
  })

  /* */

  return a.ready;

  /* */

  function testApp()
  {
    console.log( 'program::start' );
    setTimeout( () =>
    {
      console.log( 'program::end' );
    }, context.t1 * 5 ) /* 1500 */
  }
}

// --
// children
// --

function children( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let testAppPath2 = a.program( testApp2 );

  /* */

  a.ready

  .then( () =>
  {
    test.case = 'parent -> child -> child'
    var o =
    {
      execPath :  'node ' + testAppPath,
      mode : 'spawn',
      ipc : 1,
      outputCollecting : 1,
      throwingExitCode : 0
    }

    let ready = _.process.startMinimal( o );
    let children, lastChildPid;

    o.pnd.on( 'message', ( e ) =>
    {
      lastChildPid = _.numberFrom( e );
      children = _.process.children({ pid : process.pid, format : 'tree' });
    })

    ready.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      var expected =
      {
        [ process.pid ] :
        {
          [ o.pnd.pid ] :
          {
            [ lastChildPid ] : {}
          }
        }
      }
      return children.then( ( op ) =>
      {
        test.contains( op, expected );
        return null;
      })
    })

    return ready;
  })

  /* - */

  .then( () =>
  {
    test.case = 'parent -> child -> child, search from fist child'
    var o =
    {
      execPath :  'node ' + testAppPath,
      mode : 'spawn',
      ipc : 1,
      outputCollecting : 1,
      throwingExitCode : 0
    }

    let ready = _.process.startMinimal( o );
    let children, lastChildPid;

    o.pnd.on( 'message', ( e ) =>
    {
      lastChildPid = _.numberFrom( e )
      children = _.process.children({ pid : o.pnd.pid, format : 'tree' });
    })

    ready.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      var expected =
      {
        [ o.pnd.pid ] :
        {
          [ lastChildPid ] : {}
        }
      }
      return children.then( ( op ) =>
      {
        test.contains( op, expected );
        return null;
      })
    })

    return ready;
  })

  /* - */

  .then( () =>
  {
    test.case = 'parent -> child -> child, start from last child'
    var o =
    {
      execPath :  'node ' + testAppPath,
      mode : 'spawn',
      ipc : 1,
      outputCollecting : 1,
      throwingExitCode : 0
    }

    let ready = _.process.startMinimal( o );
    let children, lastChildPid;

    o.pnd.on( 'message', ( e ) =>
    {
      lastChildPid = _.numberFrom( e )
      children = _.process.children({ pid : lastChildPid, format : 'tree' });
    })

    ready.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      var expected =
      {
        [ lastChildPid ] : {}
      }
      return children.then( ( op ) =>
      {
        test.contains( op, expected );
        return null;
      })

    })

    return ready;
  })

  /* - */

  .then( () =>
  {
    test.case = 'parent -> child*'
    var o =
    {
      execPath : 'node ' + testAppPath2,
      mode : 'spawn',
      ipc : 1,
      outputCollecting : 1,
      throwingExitCode : 0
    }

    let o1 = _.mapExtend( null, o );
    let o2 = _.mapExtend( null, o );

    let r1 = _.process.startMinimal( o1 );
    let r2 = _.process.startMinimal( o2 );
    let children;

    let ready = _.Consequence.AndTake( r1, r2 );

    o1.process.on( 'message', () =>
    {
      children = _.process.children({ pid : process.pid, format : 'tree' });
    })

    ready.then( ( op ) =>
    {
      test.identical( op[ 0 ].exitCode, 0 );
      test.identical( op[ 1 ].exitCode, 0 );
      var expected =
      {
        [ process.pid ] :
        {
          [ op[ 0 ].process.pid ] : {},
          [ op[ 1 ].process.pid ] : {},
        }
      }
      return children.then( ( op ) =>
      {
        test.contains( op, expected );
        return null;
      })
    })

    return ready;
  })

  /* - */

  .then( () =>
  {
    test.case = 'only parent'
    return _.process.children({ pid : process.pid, format : 'tree' })
    // return _.process.children( process.pid )
    .then( ( op ) =>
    {
      test.contains( op, { [ process.pid ] : {} })
      return null;
    })
  })

  /* - */

  .then( () =>
  {
    test.case = 'process is not running';
    var o =
    {
      execPath : 'node ' + testAppPath2,
      mode : 'spawn',
      outputCollecting : 1,
      throwingExitCode : 0
    }

    _.process.startMinimal( o );
    o.pnd.kill('SIGKILL');

    return o.ready.then( () =>
    {
      // let ready = _.process.children( o.pnd.pid );
      let ready = _.process.children({ pid : o.pnd.pid, format : 'tree' });
      return test.shouldThrowErrorAsync( ready );
    })

  })

  /* */

  return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );
    var o =
    {
      execPath : 'node testApp2.js',
      currentPath : __dirname,
      mode : 'spawn',
      inputMirroring : 0
    }
    _.process.startMinimal( o );
    process.send( o.pnd.pid )
  }

  function testApp2()
  {
    if( process.send )
    process.send( process.pid );
    setTimeout( () => {}, context.t0 * 15 ) /* 1500 */
  }
}

//

function childrenOptionFormatList( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let testAppPath2 = a.program( testApp2 );

  /* */

  a.ready

  .then( () =>
  {
    test.case = 'parent -> child -> child'
    var o =
    {
      execPath :  'node ' + testAppPath,
      mode : 'spawn',
      ipc : 1,
      outputCollecting : 1,
      throwingExitCode : 0
    }

    let ready = _.process.startMinimal( o );
    let children, lastChildPid;

    o.pnd.on( 'message', ( e ) =>
    {
      lastChildPid = _.numberFrom( e );
      children = _.process.children({ pid : o.pnd.pid, format : 'list' })
    })

    ready.then( ( op ) =>
    {
      test.identical( op.exitCode, 0 );
      test.identical( op.ended, true );
      return children.then( ( prcocesses ) =>
      {
        if( process.platform === 'win32' )
        {
          test.identical( prcocesses.length, 4 );

          test.identical( prcocesses[ 0 ].pid, o.pnd.pid );
          test.true( _.numberIs( prcocesses[ 1 ].pid ) );
          test.identical( prcocesses[ 1 ].name, 'conhost.exe' );
          test.identical( prcocesses[ 2 ].pid, lastChildPid );
          test.identical( prcocesses[ 3 ].name, 'conhost.exe' );
          test.true( _.numberIs( prcocesses[ 3 ].pid ) );
        }
        else
        {
          var expected =
          [
            { pid : o.pnd.pid },
            { pid : lastChildPid }
          ]
          test.contains( prcocesses, expected );
        }
        return null;
      })
    })

    return ready;
  })

  /*  */

  return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    var o =
    {
      execPath : 'node testApp2.js',
      currentPath : __dirname,
      mode : 'spawn',
      inputMirroring : 0,
    }
    _.process.startMinimal( o );

    o.conStart.thenGive( () =>
    {
      process.send( o.pnd.pid );
    })
  }

  function testApp2()
  {
    setTimeout( () => {}, context.t0 * 15 ) /* 1500 */
  }
}

// --
// experiment
// --

function streamJoinExperiment()
{
  let context = this;

  let pass = new Stream.PassThrough();
  let src1 = new Stream.PassThrough();
  let src2 = new Stream.PassThrough();

  src1.pipe( pass, { end : false } );
  src2.pipe( pass, { end : false } );

  src1.on( 'data', ( chunk ) =>
  {
    console.log( 'src1.data', chunk.toString() );
  });

  src1.on( 'end', () =>
  {
    console.log( 'src1.end' );
  });

  src1.on( 'finish', () =>
  {
    console.log( 'src1.finish' );
  });

  pass.on( 'data', ( chunk ) =>
  {
    console.log( 'pass.data', chunk.toString() );
  });

  pass.on( 'end', () =>
  {
    debugger;
    console.log( 'pass.end' );
  });

  pass.on( 'finish', () =>
  {
    debugger;
    console.log( 'pass.finish' );
  });

  src1.write( 'src1a' );
  src2.write( 'src2a' );
  src1.write( 'src1b' );
  src2.write( 'src2b' );

  console.log( '1' );
  src1.end();
  console.log( '2' );
  src2.end();
  console.log( '3' );

  return _.time.out( context.t1 ); /* 1000 */
}

streamJoinExperiment.experimental = 1;

//

function experimentIpcDeasync( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let AsyncHooks = require( 'async_hooks' );

  debugger;
  console.log( `experimentIpcDeasync . executionAsyncId:${AsyncHooks.executionAsyncId()}` );
  debugger;

  // AsyncHooks.createHook
  // ({
  //   init( asyncId, type, triggerAsyncId )
  //   {
  //     console.log( `init . executionAsyncId:${AsyncHooks.executionAsyncId()}` );
  //     console.log( `init . asyncId:${asyncId} type:${type} triggerAsyncId:${triggerAsyncId}` );
  //     debugger;
  //   },
  //   before( asyncId )
  //   {
  //     // console.log( `before . asyncId:${asyncId}` );
  //   },
  //   after( asyncId )
  //   {
  //     // console.log( `after . asyncId:${asyncId}`);
  //   },
  //   destroy( asyncId )
  //   {
  //     console.log( `destroy . asyncId:${asyncId}` );
  //   },
  // }).enable();

  require( 'net' ).createServer( () => {} ).listen( 8080, () =>
  {
    // Let's wait 10ms before logging the server started.
    setTimeout( () =>
    {
      // console.log( AsyncHooks.executionAsyncId() );
    }, 10);
  });

  for( let i = 0 ; i < 10; i++ )
  a.ready.then( run )
  return a.ready;

  function run( )
  {
    var o =
    {
      execPath : 'node -e "process.send(1);setTimeout(()=>{},500)"',
      mode : 'spawn',
      stdio : 'pipe',
      ipc : 1,
      throwingExitCode : 0
    }
    _.process.start( o );

    var time = _.time.now();
    var ready = _.Consequence();

    o.pnd.on( 'message', () =>
    {
      let interval = setInterval( () =>
      {
        try
        {
          console.log( `setInterval . executionAsyncId:${AsyncHooks.executionAsyncId()}` );
          console.log( 'process.isAlive', _.time.now() - time );
          if( _.process.isAlive( o.pnd.pid ) )
          return false;
          ready.take( true );
          clearInterval( interval );
        }
        catch( err )
        {
          // console.log( err );
        }
      })
      ready.deasync();
    })

    return _.Consequence.AndKeep( o.conTerminate, ready );
  }
}

experimentIpcDeasync.experimental = 1;
experimentIpcDeasync.description =
`
This expriment shows problem with usage of _.time.periodic with deasync.
Problem happens only if code if deasync is launched from 'message' callback
`

//

function experiment( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let testAppPath2 = a.program( testApp2 );
  let o3 =
  {
    outputPiping : 1,
    outputCollecting : 1,
    applyingExitCode : 0,
    throwingExitCode : 1
  }

  let o2;

  /* - */

  a.ready.then( function()
  {
    test.case = 'mode : shell, passingThrough : true, no args';

    o =
    {
      execPath :  'node testApp.js *',
      currentPath : a.routinePath,
      mode : 'spawn',
      stdio : 'pipe'
    }

    return null;
  })
  .then( function( arg )
  {
    var options = _.mapSupplement( null, o2, o3 );

    return _.process.start( options )
    .then( function()
    {
      test.identical( options.exitCode, 0 );
      test.true( _.strHas( options.output, `[ '*' ]` ) );
      return null;
    })
  })

  return a.ready;

  /* - */

  function testApp()
  {
    let _ = require( toolsPath );
    _.include( 'wProcess' );
    _.include( 'wFiles' );

    _.process.start
    ({
      execPath : 'node testApp2.js',
      mode : 'shell',
      passingThrough : 1,
      stdio : 'inherit',
      outputPiping : 0,
      outputCollecting : 0,
      inputMirroring : 0
    })
  }

  function testApp2()
  {
    console.log( process.argv.slice( 2 ) );
  }
}

experiment.experimental = 1;

//

function experiment2( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let testAppPath = a.program( testApp );
  let track;

  var o =
  {
    execPath : 'node -e "console.log(process.ppid,process.pid)"',
    mode : 'shell',
    stdio : 'pipe'
  }
  _.process.start( o );
  console.log( 'Shell:', o.pnd.pid )

}

experiment2.experimental = 1;

//

function experiment3( test )
{
  let context = this;
  let a = context.assetFor( test, false );

  var o =
  {
    execPath : 'node -e "console.log(setTimeout(()=>{},10000))"',
    mode : 'spawn',
    stdio : 'pipe',
    timeOut : context.t1 * 2, /* 2000 */
    throwingExitCode : 0
  }
  _.process.start( o );

  o.conTerminate.then( ( op ) =>
  {
    test.identical( op.ended, true );
    test.identical( op.exitReason, 'signal' );
    test.identical( op.exitCode, null );
    test.identical( op.exitSignal, 'SIGTERM' );
    test.true( !_.process.isAlive( op.pnd.pid ) );
    return null;
  })

  return o.conTerminate;
}

experiment3.experimental = 1;
experiment3.description =
`
Shows that timeOut kills the child process and handleClose is called
`

// --
// suite
// --

var Proto =
{

  name : 'Tools.l4.process.Execution',
  silencing : 1,
  routineTimeOut : 60000,
  onSuiteBegin : suiteBegin,
  onSuiteEnd : suiteEnd,

  context :
  {

    assetFor,
    suiteTempPath : null,

    t0 : 100,
    t1 : 1000,
    t2 : 5000,
    t3 : 15000,

  },

  tests :
  {

    // basic

    startMinimalBasic,
    startMinimalFork, /* qqq for Yevhen : subroutine for modes */
    startMinimalErrorHandling,

    // sync

    startMinimalSync,
    startSingleSyncDeasync,
    startMinimalSyncDeasyncThrowing,
    startMultipleSyncDeasync,

    // arguments

    startMinimalWithoutExecPath,
    startMinimalArgsOption,
    startMinimalArgumentsParsing,
    startMinimalArgumentsParsingNonTrivial,
    startMinimalArgumentsNestedQuotes,
    startMinimalExecPathQuotesClosing,
    startMinimalExecPathSeveralCommands,
    startExecPathNonTrivialModeShell, /* with `starter` */
    startArgumentsHandlingTrivial, /* with `starter` */
    startArgumentsHandling, /* with `starter` */
    startImportantExecPath, /* with `starter` */
    startMinimalImportantExecPathPassingThrough,
    startNormalizedExecPath, /* with `starter` */
    startMinimalExecPathWithSpace,
    startMinimalDifferentTypesOfPaths,
    startNjsPassingThroughExecPathWithSpace,
    startNjsPassingThroughDifferentTypesOfPaths,
    startMinimalPassingThroughExecPathWithSpace,

    // procedures / chronology / structural

    startProcedureTrivial, /* with `starter` */
    startProcedureExists, /* with `starter` */
    startSingleProcedureStack, /* xxx : passes only when run with `start`, `startMinimal` */
    startMultipleProcedureStack,
    startMinimalOnTerminateSeveralCallbacksChronology,
    startMinimalChronology,
    startMultipleState,

    // delay

    startSingleReadyDelay,
    startMultipleReadyDelay,
    startMinimalOptionWhenDelay,
    startMinimalOptionWhenTime,
    startMinimalOptionTimeOut,
    startAfterDeath, /* qqq for Vova : does not work if call is _.process.startSingle() */
    startAfterDeathOutput, /* qqq for Vova : does not work if call is _.process.startSingle() */

    // detaching

    startMinimalDetachingResourceReady,
    startMinimalDetachingNoTerminationBegin,
    startMinimalDetachedOutputStdioIgnore,
    startMinimalDetachedOutputStdioPipe,
    startMinimalDetachedOutputStdioInherit,
    startMinimalDetachingIpc,

    startMinimalDetachingTrivial,
    startMinimalDetachingChildExitsAfterParent,
    startMinimalDetachingChildExitsBeforeParent,
    startMinimalDetachingDisconnectedEarly,
    startMinimalDetachingDisconnectedLate,
    startMinimalDetachingChildExistsBeforeParentWaitForTermination,
    startMinimalDetachingEndCompetitorIsExecuted,
    startMinimalDetachingTerminationBegin,
    startMinimalEventClose,
    startMinimalEventExit,
    startMinimalDetachingThrowing,
    startNjsDetachingChildThrowing,

    // on

    startMinimalOnStart,
    startMinimalOnTerminate,
    startMinimalNoEndBug1,
    startMinimalWithDelayOnReady,
    startMinimalOnIsNotConsequence,

    // concurrent

    startMultipleConcurrent,
    startMultipleConcurrentConsequences,
    starterConcurrentMultiple, /* with `starter` */

    // helper

    startNjs,
    startNjsWithReadyDelayStructural,
    startNjsOptionInterpreterArgs,
    startNjsWithReadyDelayStructuralMultiple,

    // starter

    starter,
    starterArgs,
    starterFields,

    // output

    startMinimalOptionOutputCollecting,
    startMinimalOptionOutputColoring,
    startMinimalOptionOutputColoringStderr,
    startMinimalOptionOutputColoringStdout,
    startMinimalOptionOutputGraying,
    startMinimalOptionOutputPrefixing,
    startMinimalOptionOutputPiping,
    startMinimalOptionInputMirroring,
    startMinimalOptionLogger,
    startMinimalOptionLoggerTransofrmation,
    startMinimalOutputOptionsCompatibilityLateCheck,
    startMinimalOptionVerbosity,
    startMinimalOptionVerbosityLogging,
    startMultipleOutput,
    startMultipleOptionStdioIgnore,

    // etc

    appTempApplication,

    // other options

    startMinimalOptionStreamSizeLimit,
    startMinimalOptionStreamSizeLimitThrowing,
    startSingleOptionDry,
    startMultipleOptionDry,
    startSingleOptionCurrentPath,
    startMultipleOptionCurrentPath,
    startPassingThrough,
    startMinimalOptionUid,
    startMinimalOptionGid,
    startSingleOptionProcedure,
    startMultipleOptionProcedure,

    // pid / status / exit

    startMinimalDiffPid,
    pidFrom,

    isAlive,
    statusOf,

    exitReason,
    exitCode, /* qqq for Yevhen : check order of test routines. it's messed up */

    // termination

    kill,
    killSync,
    killOptionWithChildren,

    startMinimalErrorAfterTerminationWithSend,
    startMinimalTerminateHangedWithExitHandler,
    startMinimalTerminateAfterLoopRelease,

    endSignalsBasic,
    endSignalsOnExit,
    endSignalsOnExitExitAgain,

    terminate,
    terminateSync,

    terminateFirstChild,
    terminateSecondChild,
    terminateDetachedFirstChild,
    terminateWithDetachedChild,

    terminateSeveralChildren,
    terminateSeveralDetachedChildren,
    terminateDeadProcess,

    terminateTimeOutNoHandler,
    terminateTimeOutIgnoreSignal,
    terminateZeroTimeOut,
    terminateZeroTimeOutWithoutChildrenShell,
    terminateZeroTimeOutWithChildrenShell,

    terminateDifferentStdio,

    killComplex,
    execPathOf,
    waitForDeath,

    // children

    children,
    childrenOptionFormatList,

    // experiments

    experimentIpcDeasync,
    streamJoinExperiment,
    experiment,
    experiment2,
    experiment3,

  }

}

_.mapExtend( Self, Proto );

//

Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self );

})();
