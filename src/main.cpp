/***********************************************************************************                                                               
* Copyright (c) 2020, Goethe University Frankfurt, G-CSC                           *                                                               
* Author: Arne Naegel                                                              *                                                               
*                                                                                  *                                                               
* Distributed under the terms of the BSD 3-Clause License.                         *                                                               
*                                                                                  *                                                               
* The full license is in the file LICENSE, distributed with this software.         *                                                               
************************************************************************************/
#include <memory>


#include <xeus-zmq/xserver_zmq.hpp>
#include <xeus/xeus_context.hpp>
#include <xeus/xhelper.hpp>
#include <xeus/xkernel.hpp>
#include <xeus/xkernel_configuration.hpp>
#include <xeus/xlogger.hpp>

#include "custom_interpreter.hpp"

int main(int argc, char* argv[])
{
    // Load configuration file
    std::string file_name = (argc == 1) ? "connection.json" : argv[2];
    xeus::xconfiguration config = xeus::load_configuration(file_name);

    // Create interpreter instance
    using interpreter_ptr = std::unique_ptr<ug::xeus_interpreter>;
    interpreter_ptr interpreter = interpreter_ptr(new ug::xeus_interpreter());

    // Create kernel instance and start it
   // xeus::xkernel kernel(config, xeus::get_user_name(), std::move(interpreter));

    auto context = xeus::make_context<zmq::context_t>();
    xeus::xkernel kernel(config,
                             xeus::get_user_name(),
                             std::move(context),
                             std::move(interpreter),
                             xeus::make_xserver_zmq);

    kernel.start();

    return 0;
}
