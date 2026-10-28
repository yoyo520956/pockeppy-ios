#include "Python.h"
#include "pyembed.h"
#include <string.h>

static PyObject *g_main = NULL;

bool ppy_init(const char *homePath) {
    if (Py_IsInitialized()) {
        g_main = PyImport_ImportModule("__main__");
        return g_main != NULL;
    }
    PyStatus status;
    PyConfig config;
    status = PyConfig_InitPythonConfig(&config);
    if (PyStatus_Exception(status)) {
        return false;
    }
    config.isolated = 1;                    // 忽略 PYTHON* 环境变量
    config.install_signal_handlers = 0;     // iOS 不能装信号处理器
    config.write_bytecode = 0;              // 沙盒只读，不写 pyc
    if (homePath != NULL) {
        wchar_t *whome = Py_DecodeLocale(homePath, NULL);
        if (whome != NULL) {
            status = PyConfig_SetString(&config, &config.home, whome);
            PyMem_RawFree(whome);
            if (PyStatus_Exception(status)) {
                PyConfig_Clear(&config);
                return false;
            }
        }
    }
    status = Py_InitializeFromConfig(&config);
    if (PyStatus_Exception(status)) {
        PyConfig_Clear(&config);
        return false;
    }
    PyConfig_Clear(&config);
    g_main = PyImport_ImportModule("__main__");
    return g_main != NULL;
}

const char *ppy_version(void) {
    return Py_GetVersion();
}

char *ppy_run(const char *code) {
    if (!Py_IsInitialized() || g_main == NULL) {
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"Python engine not initialized\",\"tb\":\"\"}");
    }
    // 用户代码注入 __main__.pypocket_src
    PyObject *moddict = PyModule_GetDict(g_main);
    if (moddict == NULL) {
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"__main__ module missing\",\"tb\":\"\"}");
    }
    PyObject *src = PyUnicode_FromString(code != NULL ? code : "");
    if (src == NULL) {
        PyErr_Clear();
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"internal: bad code buffer\",\"tb\":\"\"}");
    }
    if (PyDict_SetItemString(moddict, "pypocket_src", src) != 0) {
        Py_DECREF(src);
        PyErr_Clear();
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"internal: cannot set pypocket_src\",\"tb\":\"\"}");
    }
    Py_DECREF(src);

    static const char *SCRIPT =
        "import sys, io, traceback\n"
        "_so, _se = io.StringIO(), io.StringIO()\n"
        "_o, _e = sys.stdout, sys.stderr\n"
        "sys.stdout, sys.stderr = _so, _se\n"
        "pypocket_result = {'ok': True, 'stdout': '', 'stderr': '', 'tb': ''}\n"
        "try:\n"
        "    exec(compile(pypocket_src, '<user.py>', 'exec'))\n"
        "except BaseException:\n"
        "    pypocket_result['ok'] = False\n"
        "    pypocket_result['tb'] = traceback.format_exc()\n"
        "finally:\n"
        "    sys.stdout, sys.stderr = _o, _e\n"
        "    pypocket_result['stdout'] = _so.getvalue()\n"
        "    pypocket_result['stderr'] = _se.getvalue()\n";

    if (PyRun_SimpleString(SCRIPT) != 0) {
        // 脚本本身执行出错（理论上不该发生），记录后继续
    }
    PyObject *resObj = PyDict_GetItemString(moddict, "pypocket_result");
    if (resObj == NULL) {
        PyErr_Clear();
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"internal: pypocket_result missing\",\"tb\":\"\"}");
    }
    PyObject *jsonmod = PyImport_ImportModule("json");
    PyObject *js = jsonmod ? PyObject_CallMethod(jsonmod, "dumps", "O", resObj) : NULL;
    Py_XDECREF(jsonmod);
    if (js == NULL) {
        PyErr_Clear();
        return strdup("{\"ok\":false,\"stdout\":\"\",\"stderr\":\"internal: json encode failed\",\"tb\":\"\"}");
    }
    const char *s = PyUnicode_AsUTF8(js);
    char *out = strdup(s != NULL ? s : "{\"ok\":false}");
    Py_DECREF(js);
    return out;
}

void ppy_free(char *p) {
    free(p);
}
