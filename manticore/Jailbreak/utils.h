//
//  utils.h
//  reton
//
//  Created by Luca on 18.02.21.
//

#ifndef utils_h
#define utils_h

int perform_root_patches(kptr_t ucred);
char *get_path_for_pid(pid_t pid);
pid_t pid_of_process(const char *name);
bool restartSpringBoard(void);
int runCommandv(const char *cmd, int argc, const char * const* argv, void (^unrestrict)(pid_t), bool wait);
int runCommand(const char *cmd, ...);
#endif /* utils_h */
