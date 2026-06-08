/*
 *
 *  [xavier@Xpc data-race]$ time { g++ -std=c++20 main.cpp && ./a.out lck; }
 *  30,000,000 + 30,000,000 = 60,000,000 with std::mutex
 *  
 *  real    0m5.789s
 *  user    0m6.315s
 *  sys     0m4.087s
 *  [xavier@Xpc data-race]$ time { g++ -std=c++20 main.cpp && ./a.out atomic; }
 *  30,000,000 + 30,000,000 = 60,000,000 with std::atomic
 *  
 *  real    0m1.642s
 *  user    0m2.053s
 *  sys     0m0.117s
 *  [xavier@Xpc data-race]$ time { g++ -std=c++20 main.cpp && ./a.out; }
 *  30,000,000 + 30,000,000 = 35,597,410 with None
 *  
 *  real    0m1.358s
 *  user    0m1.515s
 *  sys     0m0.108s
 *
 */

#include <thread>
#include <iostream>
#include <mutex>
#include <format>
#include <string.h>
#include <atomic>

// 1. 参数解析模块：检查运行模式
std::string parse_method(int argc, char *argv[])
{
    if (argc < 2)
        return "None";
    else if (strcmp(argv[1], "lck") == 0)
        return "std::mutex";
    else if (strcmp(argv[1], "atomic") == 0)
        return "std::atomic";
    else
        return "None";
}

// 3. 主函数：负责流程编排与结果输出
int main(int argc, char *argv[])
{
    // 解析配置
    const std::string method = parse_method(argc, argv);

    // 初始化共享资源
    const size_t count = 3e7;
    size_t sum = 0;

    // 使用锁
    std::mutex sumMtx;

    // 使用原子
    std::atomic<size_t> sum_atomic{0};

    auto task = [&]()
    {
        for (size_t i = 0; i < count; ++i)
        {
            if (method == "std::mutex")
            {
                std::lock_guard<std::mutex> lck(sumMtx);
                ++sum;
            }
            else if (method == "std::atomic")
            {
                ++sum_atomic;
            }
            else
            {
                ++sum;
            }
        }
    };

    // 启动多线程
    auto thraed_1 = std::thread(task);
    auto thraed_2 = std::thread(task);

    // 等待线程完成
    thraed_1.join();
    thraed_2.join();

    // 格式化输出结果
    std::locale::global(std::locale(""));
    std::cout << std::format("{:L} + {:L} = {:L} with {}", count, count, sum ? sum : sum_atomic.load(), method) << std::endl;

    return 0;
}